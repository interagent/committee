module Committee::Drivers
  class OpenAPI2
    def parse(data)
      REQUIRED_FIELDS.each do |field|
        if !data[field]
          raise ArgumentError, "Committee: no #{field} section in spec data."
        end
      end

      if data['swagger'] != '2.0'
        raise ArgumentError, "Committee: driver requires OpenAPI 2.0."
      end

      spec = Spec.new

      spec.base_path = data['basePath'] || '/'

      # Arbitrarily choose the first media type found in these arrays. This
      # appraoch could probably stand to be improved, but at least users will
      # for now have the option of turning media type validation off if they so
      # choose.
      spec.consumes = data['consumes'].first
      spec.produces = data['produces'].first

      spec.definitions, store = parse_definitions!(data)
      spec.routes = parse_routes!(data, spec, store)

      spec
    end

    # Link abstracts an API link specifically for OpenAPI 2.
    class Link
      # The link's input media type. i.e. How requests should be encoded.
      attr_accessor :enc_type

      attr_accessor :href

      # The link's output media type. i.e. How responses should be encoded.
      attr_accessor :media_type

      attr_accessor :method

      # The link's input schema. i.e. How we validate an endpoint's incoming
      # parameters.
      attr_accessor :schema

      attr_accessor :status_success

      # The link's output schema. i.e. How we validate an endpoint's response
      # data.
      attr_accessor :target_schema

      def rel
        raise "Committee: rel not implemented for OpenAPI"
      end
    end

    class Spec
      attr_accessor :base_path
      attr_accessor :consumes
      attr_accessor :definitions
      attr_accessor :produces
      attr_accessor :routes
    end

    private

    DEFINITIONS_PSEUDO_URI = "http://json-schema.org/committee-definitions"

    # These are fields that the OpenAPI 2 spec considers mandatory to be
    # included in the document's top level.
    REQUIRED_FIELDS = [
      :consumes,
      :definitions,
      :paths,
      :produces,
      :swagger,
    ].map(&:to_s).freeze

    def find_best_fit_response(link_data)
      if response_data = link_data["responses"]["200"]
        [200, response_data]
      elsif response_data = link_data["responses"]["201"]
        [201, response_data]
      else
        # Sort responses so that we can try to prefer any 3-digit status code.
        # If there are none, we'll just take anything from the list.
        ordered_responses = link_data["responses"].
          select { |k, v| k =~ /[0-9]{3}/ }
        if first = ordered_responses.first
          [first[0].to_i, first[1]]
        else
          [nil, nil]
        end
      end
    end

    def href_to_regex(href)
      href.gsub(/\{(.*?)\}/, "[^/]+")
    end

    def parse_definitions!(data)
      # The "definitions" section of an OpenAPI 2 spec is a valid JSON schema.
      # We extract it from the spec and parse it as a schema in isolation so
      # that all references to it will still have correct paths (i.e. we can
      # still find a resource at '#/definitions/resource' instead of
      # '#/resource').
      schema = JsonSchema.parse!({
        "definitions" => data['definitions'],
      })
      schema.expand_references!
      schema.uri = DEFINITIONS_PSEUDO_URI

      # So this is a little weird: an OpenAPI specification is _not_ a valid
      # JSON schema and yet it self-references like it is a valid JSON schema.
      # To work around this what we do is parse its "definitions" section as a
      # JSON schema and then build a document store here containing that. When
      # trying to resolve a reference from elsewhere in the spec, we build a
      # synthetic schema with a JSON reference to the document created from
      # "definitions" and then expand references against this store.
      store = JsonSchema::DocumentStore.new
      store.add_schema(schema)

      [schema, store]
    end

    def parse_routes!(data, spec, store)
      routes = {}
      data['paths'].each do |path, methods|
        methods.each do |method, link_data|
          method = method.upcase

          link = Link.new
          link.href = spec.base_path + path
          link.method = method

          # TODO: Need to implement request schema.
          link.schema = nil

          # Arbitrarily pick one response for the time being. Prefers in order:
          # a 200, 201, any 3-digit numerical response, then anything at all.
          status, response_data = find_best_fit_response(link_data)
          if status
            link.status_success = status

            # See the note on our DocumentStore's initialization in
            # #parse_definitions!, but what we're doing here is prefixing
            # references with a specialized internal URI so that they can
            # reference definitions from another document in the store.
            target_schema = rewrite_references(response_data["schema"])

            # A link need not necessarily specify a target schema.
            if target_schema
              target_schema = JsonSchema.parse!(target_schema)
              target_schema.expand_references!(store: store)
              link.target_schema = target_schema
            end
          end

          routes[method] ||= []
          routes[method] << [%r{^#{href_to_regex(link.href)}$}, link]
        end
      end
      routes
    end

    def rewrite_references(schema)
      if schema.is_a?(Hash)
        ref = schema["$ref"]
        if ref && ref.is_a?(String) && ref[0] == "#"
          schema["$ref"] = DEFINITIONS_PSEUDO_URI + ref
        else
          schema.each do |_, v|
            rewrite_references(v)
          end
        end
      end
      schema
    end
  end
end

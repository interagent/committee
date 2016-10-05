module Committee::Drivers
  class OpenAPI2
    # These are fields that the OpenAPI 2 spec considers mandatory to be
    # included in the document's top level.
    REQUIRED_FIELDS = [
      :consumes,
      :definitions,
      :paths,
      :produces,
      :swagger,
    ].map(&:to_s).freeze

    def build_routes(spec)
    end

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

      # The "definitions" section of an OpenAPI 2 spec is a valid JSON schema.
      # We extract it from the spec and parse it as a schema in isolation so
      # that all references to it will still have correct paths (i.e. we can
      # still find a resource at '#/definitions/resource' instead of
      # '#/resource').
      schema = JsonSchema.parse!({
        "definitions": data['definitions'],
      })
      schema.expand_references!
      spec.definitions = schema

      routes = {}
      data['paths'].each do |path, methods|
        methods.each do |method, link_data|
          method = method.upcase

          link = Link.new
          link.href = spec.base_path + path
          link.method = method

          # TODO: Need to implement request schema.
          link.schema = nil

          status, response_data = find_best_fit_response(link_data)
          if status
            link.status_success = status

            # TODO: Need to resolve references in response schema.
            link.target_schema = response_data["schema"]
          end

          routes[method] ||= []
          routes[method] << link
        end
      end
      spec.routes = routes

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

    def find_best_fit_response(link_data)
      if response_data = link_data["responses"]["200"]
        [200, response_data]
      elsif response_data = link_data["responses"]["201"]
        [201, response_data]
      else
        ordered_responses = link_data["responses"].
          select { |k, v| k =~ /[0-9]{3}/ }
        if first = ordered_responses.first
          [first[0].to_i, first[1]]
        else
          [nil, nil]
        end
      end
    end
  end
end

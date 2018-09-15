module Committee::Drivers
  class OpenAPI3 < Committee::Drivers::Driver
    # Whether parameters that were form-encoded will be coerced by default.
    def default_coerce_form_params
      true
    end

    # Whether parameters in a request's path will be considered and coerced by
    # default.
    def default_path_params
      true
    end

    # Whether parameters in a request's query string will be considered and
    # coerced by default.
    def default_query_params
      true
    end

    def name
      :open_api_3
    end

    # Parses an API schema and builds a set of route definitions for use with
    # Committee.
    #
    # The expected input format is a data hash with keys as strings (as opposed
    # to symbols) like the kind produced by JSON.parse or YAML.load.
    def parse(data)
      data = convert_components_to_definitions(data)
      REQUIRED_FIELDS.each do |field|
        if !data[field]
          raise ArgumentError, "Committee: no #{field} section in spec data."
        end
      end

      openapi_version = Gem::Version.create(data['openapi'])
      unless Gem::Version.create('3.0.0') <= openapi_version && openapi_version < Gem::Version.create('4.0.0')
        raise ArgumentError, "Committee: driver requires OpenAPI 3."
      end

      schema = Schema.new
      schema.driver = self

      schema.definitions, store = parse_definitions!(data)
      schema.routes = parse_routes!(data, schema, store)

      schema
    end

    def schema_class
      Committee::Drivers::OpenAPI3::Schema
    end

    # gem json_schema seems not support #components so so far it needs to be converted to #definitions
    def convert_components_to_definitions(data)
      JSON.parse(
        data.to_json.
        gsub('"components":', '"definitions":').
        gsub("#/components/schemas", "#/definitions")
      )
    end

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

      attr_accessor :header_schema

      def rel
        raise "Committee: rel not implemented for OpenAPI"
      end
    end

    class SchemaBuilder
      def initialize(link_data)
        self.link_data = link_data
      end

      private

      LINK_REQUIRED_FIELDS = [
        :name
      ].map(&:to_s).freeze

      attr_accessor :link_data

      def check_required_fields!(param_data)
        LINK_REQUIRED_FIELDS.each do |field|
          if !param_data[field]
            raise ArgumentError,
                  "Committee: no #{field} section in link data."
          end
        end
      end
    end

    class HeaderSchemaBuilder < SchemaBuilder
      def call
        if link_data["parameters"]
          link_schema = JsonSchema::Schema.new
          link_schema.properties = {}
          link_schema.required = []

          header_parameters = link_data["parameters"].select { |param_data| param_data["in"] == "header" }
          header_parameters.each do |param_data|
            check_required_fields!(param_data)

            param_schema = JsonSchema::Schema.new

            param_schema.type = [param_data["type"]]

            link_schema.properties[param_data["name"]] = param_schema
            if param_data["required"] == true
              link_schema.required << param_data["name"]
            end
          end

          link_schema
        end
      end
    end

    # ParameterSchemaBuilder converts link parameters, which are not
    # quite JSON schemas into synthetic schemas that
    # we can use to do some basic request validation.
    # We couldn't fully adjust to openapi3 and using converted OpenAPI 2 link parameter.
    # so still using ParameterSchemaBuilder

    class ParameterSchemaBuilder < SchemaBuilder
      # Returns a tuple of (schema, schema_data) where only one of the two
      # values is present. This is either a full schema that's ready to go _or_
      # a hash of unparsed schema data.
      def call
        if link_data["parameters"]
          link_schema = JsonSchema::Schema.new
          link_schema.properties = {}
          link_schema.required = []

          parameters = link_data["parameters"].reject { |param_data| param_data["in"] == "header" }
          parameters.each do |param_data|
            check_required_fields!(param_data)

            param_schema = JsonSchema::Schema.new

            # We could probably use more validation here, but the formats
            # are based off of what's available in JSON schema, and
            # therefore this should map over quite well.
            param_schema.type = [param_data["schema"]["type"]] if param_data["schema"].is_a?(Hash)

            # And same idea: despite parameters not being schemas, the items
            # key (if preset) is actually a schema that defines each item of an
            # array type, so we can just reflect that directly onto our
            # artifical schema.
            if param_data["schema"].is_a?(Hash) && param_data["schema"]["type"] == "array" && param_data["schema"]["items"]
              param_schema.items = param_data["schema"]["items"]
            end

            link_schema.properties[param_data["name"]] = param_schema
            if param_data["required"] == true
              link_schema.required << param_data["name"]
            end
          end
          [link_schema, nil]
        elsif link_data["requestBody"]
          body_param = link_data["requestBody"]
          schema_data = body_param["content"]["application/json"]["schema"] # check only first item
          [nil, schema_data]
        end
      end
    end

    class Schema < Committee::Drivers::Schema
      # A link back to the derivative instace of Committee::Drivers::Driver
      # that create this schema.
      attr_accessor :driver

      attr_accessor :definitions
      attr_accessor :routes
    end

    private

    DEFINITIONS_PSEUDO_URI = "http://json-schema.org/committee-definitions"

    # These are fields that the OpenAPI 3 spec considers mandatory to be
    # included in the document's top level.
    REQUIRED_FIELDS = [
      :openapi,
      :info,
      :paths,
    ].map(&:to_s).freeze

    def find_best_fit_response(link_data)
      return [nil, nil] if link_data["responses"].nil?
      response_data_200 =
        link_data["responses"]['200'] || link_data["responses"][200]

      response_data_201 =
        link_data["responses"]['201'] || link_data["responses"][201]

      if response_data_200 &&
          response_data_200["content"] &&
          response_data_200["content"]["application/json"] &&
          data = response_data_200["content"]["application/json"]["schema"]
        [200, data]
      elsif response_data_201 &&
          response_data_201["content"] &&
          response_data_201["content"]["application/json"] &&
          data = response_data_201["content"]["application/json"]["schema"]
        [201, data]
      else
        # Sort responses so that we can try to prefer any 3-digit status code.
        # If there are none, we'll just take anything from the list.
        first_ordered_response = link_data["responses"].
          select { |k, v| k =~ /[0-9]{3}/ }.first
        if first_ordered_response &&
          first_ordered_response[1]["content"] &&
          first_ordered_response[1]["content"]["application/json"] &&
          data = first_ordered_response[1]["content"]["application/json"]["schema"]
          [first_ordered_response[0].to_i, data]
        else
          [nil, nil]
        end
      end
    end

    def href_to_regex(href)
      href.gsub(/\{(.*?)\}/, '(?<\1>[^/]+)')
    end

    def parse_definitions!(data)
      # The "components" of an OpenAPI 3 section is not valid for gem "json_schema" so convert them
      # using convert_components_to_definitions
      schema = JsonSchema.parse!({
        "definitions" => data['definitions']['schemas'],
      })
      # schema = JsonSchema.parse!(data)
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

    def parse_routes!(data, schema, store)
      routes = {}

      # This is a performance optimization: instead of going through each link
      # and parsing out its JSON schema separately, instead we just aggregate
      # all schemas into one big hash and then parse it all at the end. After
      # we parse it, go through each link and assign a proper schema object. In
      # practice this comes out to somewhere on the order of 50x faster.
      schemas_data = { "properties" => {} }

      # Exactly the same idea, but for response schemas.
      target_schemas_data = { "properties" => {} }

      data['paths'].each do |path, methods|
        schemas_data["properties"][path] = { "properties" => {} }
        target_schemas_data["properties"][path] = { "properties" => {} }

        methods.each do |method, link_data|
          method = method.upcase

          link = Link.new
          link.href = path
          link.method = method

          # Convert the spec's parameter pseudo-schemas into JSON schemas that
          # we can use for some basic request validation.
          link.schema, schema_data = ParameterSchemaBuilder.new(link_data).call
          link.header_schema = HeaderSchemaBuilder.new(link_data).call

          # If data came back instead of a schema (this occurs when a route has
          # a single `body` parameter instead of a collection of URL/query/form
          # parameters), store it for later parsing.
          if schema_data
            schemas_data["properties"][path]["properties"][method] = schema_data
          end

          # Arbitrarily pick one response for the time being. Prefers in order:
          # a 200, 201, any 3-digit numerical response, then anything at all.
          status, response_data = find_best_fit_response(link_data)
          if status
            link.status_success = status

            # A link need not necessarily specify a target schema.
            if response_data
              target_schemas_data["properties"][path]["properties"][method] =
                response_data
            end
            # link.media_type = response_data["content"]&.keys&.first
          end

          rx = %r{^#{href_to_regex(link.href)}$}
          Committee.log_debug "Created route: #{link.method} #{link.href} (regex #{rx})"

          routes[method] ||= []
          routes[method] << [rx, link]
        end
      end

      # See the note on our DocumentStore's initialization in
      # #parse_definitions!, but what we're doing here is prefixing references
      # with a specialized internal URI so that they can reference definitions
      # from another document in the store.
      schemas =
        rewrite_references_and_parse(schemas_data, store)
      target_schemas =
        rewrite_references_and_parse(target_schemas_data, store)

      # As noted above, now that we've parsed our aggregate response schema, go
      # back through each link and them their response schema.
      routes.each do |method, method_routes|
        method_routes.each do |(_, link)|
          # request
          #
          # Differs slightly from responses in that the schema may already have
          # been set for endpoints with non-body parameters, so check for nil
          # before we set it.
          if schema = schemas.properties[link.href].properties[method]
            link.schema = schema
          end

          # response
          link.target_schema =
            target_schemas.properties[link.href].properties[method]
        end
      end

      routes
    end

    def rewrite_references_and_parse(schemas_data, store)
      schemas = rewrite_references(schemas_data)
      schemas = JsonSchema.parse!(schemas_data)
      schemas.expand_references!(:store => store)
      schemas
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
      elsif schema.is_a?(Array)
        schema.each do |v|
          rewrite_references(v)
        end
      end
      schema
    end
  end
end

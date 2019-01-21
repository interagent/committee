module Committee::Drivers
  class HyperSchema < Committee::Drivers::Driver
    def default_coerce_date_times
      false
    end

    # Whether parameters that were form-encoded will be coerced by default.
    def default_coerce_form_params
      false
    end

    # Whether parameters in a request's path will be considered and coerced by
    # default.
    def default_path_params
      false
    end

    # Whether parameters in a request's query string will be considered and
    # coerced by default.
    def default_query_params
      false
    end

    def default_validate_success_only
      true
    end

    def name
      :hyper_schema
    end

    # Parses an API schema and builds a set of route definitions for use with
    # Committee.
    #
    # The expected input format is a data hash with keys as strings (as opposed
    # to symbols) like the kind produced by JSON.parse or YAML.load.
    def parse(schema)
      # Really we'd like to only have data hashes passed into drivers these
      # days, but here we handle a JsonSchema::Schema for now to maintain
      # backward compatibility (this library used to be hyper-schema only).
      if schema.is_a?(JsonSchema::Schema)
        hyper_schema = schema
      else
        hyper_schema = JsonSchema.parse!(schema)
        hyper_schema.expand_references!
      end

      schema = Schema.new
      schema.driver = self
      schema.routes = build_routes(hyper_schema)
      schema
    end

    def schema_class
      Committee::Drivers::HyperSchema::Schema
    end

    # Link abstracts an API link specifically for JSON hyper-schema.
    #
    # For most operations, it's a simple pass through to a
    # JsonSchema::Schema::Link, but implements some exotic behavior in a few
    # places.
    class Link
      def initialize(hyper_schema_link)
        self.hyper_schema_link = hyper_schema_link
      end

      # The link's input media type. i.e. How requests should be encoded.
      def enc_type
        hyper_schema_link.enc_type
      end

      def href
        hyper_schema_link.href
      end

      # The link's output media type. i.e. How responses should be encoded.
      def media_type
        hyper_schema_link.media_type
      end

      def method
        hyper_schema_link.method
      end

      # Passes through a link's parent resource. Note that this is *not* part
      # of the Link interface and is here to support a legacy Heroku-ism
      # behavior that allowed a link tagged with rel=instances to imply that a
      # list will be returned.
      def parent
        hyper_schema_link.parent
      end

      def rel
        hyper_schema_link.rel
      end

      # The link's input schema. i.e. How we validate an endpoint's incoming
      # parameters.
      def schema
        hyper_schema_link.schema
      end

      def status_success
        hyper_schema_link.rel == "create" ? 201 : 200
      end

      # The link's output schema. i.e. How we validate an endpoint's response
      # data.
      def target_schema
        hyper_schema_link.target_schema
      end

      private

      attr_accessor :hyper_schema_link
    end

    class Schema < Committee::Drivers::Schema
      # A link back to the derivative instace of Committee::Drivers::Driver
      # that create this schema.
      attr_accessor :driver

      attr_accessor :routes

      attr_reader :validator_option

      def build_router(options)
        @validator_option = Committee::SchemaValidator::Option.new(options, self, :hyper_schema)
        Committee::SchemaValidator::HyperSchema::Router.new(self, @validator_option)
      end
    end

    private

    def build_routes(hyper_schema)
      routes = {}

      hyper_schema.links.each do |link|
        method, href = parse_link(link)
        next unless method

        rx = %r{^#{href}$}
        Committee.log_debug "Created route: #{method} #{href} (regex #{rx})"

        routes[method] ||= []
        routes[method] << [rx, Link.new(link)]
      end

      # recursively iterate through all `properties` subschemas to build a
      # complete routing table
      hyper_schema.properties.each do |_, subschema|
        routes.merge!(build_routes(subschema)) { |_, r1, r2| r1 + r2 }
      end

      routes
    end

    def href_to_regex(href)
      href.gsub(/\{(.*?)\}/, "[^/]+")
    end

    def parse_link(link)
      return nil, nil if !link.method || !link.href
      method = link.method.to_s.upcase
      # /apps/{id} --> /apps/([^/]+)
      href = href_to_regex(link.href)
      [method, href]
    end
  end
end

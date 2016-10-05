module Committee::Drivers
  class HyperSchema
    def build_routes(schema)
      routes = {}

      schema.links.each do |link|
        method, href = parse_link(link)
        next unless method
        routes[method] ||= []
        routes[method] << [%r{^#{href}$}, Link.new(link)]
      end

      # recursively iterate through all `properties` subschemas to build a
      # complete routing table
      schema.properties.each do |_, subschema|
        routes.merge!(build_routes(subschema)) { |_, r1, r2| r1 + r2 }
      end

      routes
    end

    def parse(schema)
      schema = JsonSchema.parse!(schema)
      schema.expand_references!
      schema
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

      def target_schema
        # Falling back on the link's parent schema is legacy behavior to
        # support existing Heroku hyper-schemas that don't have a
        # `targetSchema` defined. It's non-standard and shouldn't be relied
        # upon.
        hyper_schema_link.target_schema || hyper_schema_link.parent
      end

      private

      attr_accessor :hyper_schema_link
    end

    private

    def parse_link(link)
      return nil, nil if !link.method || !link.href
      method = link.method.to_s.upcase
      # /apps/{id} --> /apps/([^/]+)
      href = link.href.gsub(/\{(.*?)\}/, "[^/]+")
      [method, href]
    end
  end
end

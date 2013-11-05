require "multi_json"

module Rack
  class Committee
    class RoutesBuilder
      def initialize(schemata)
        @schemata = schemata
      end

      def call
        routes = {}
        @schemata.each do |_, schema|
          schema["links"].each do |link|
            routes[link["method"]] ||= []
            # /apps/{id} --> /apps/([^/]+)
            pattern = link["href"].gsub(/\{(.*)\}/, "([^/]+)")
            routes[link["method"]] << [Regexp.new(pattern), link]
          end
        end
        routes
      end
    end

    def initialize(app, options={})
      @app = app

      blobs = options[:schema] || raise("need option `schema`")
      blobs = [blobs] if !blobs.is_a?(Array)

      @schemata = {}
      blobs.map { |b| MultiJson.decode(b) }.each do |schema|
        @schemata[schema["id"]] = schema
      end
      @routes = RoutesBuilder.new(@schemata).call
    end

    def call(env)
      if method_routes = @routes[env["REQUEST_METHOD"]]
        method_routes.each do |pattern, link|
          if env["PATH_INFO"] =~ pattern
            puts "COMMITTEE"
          end
        end
      end
      @app.call(env)
    end
  end
end

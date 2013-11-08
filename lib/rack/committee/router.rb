module Rack::Committee
  class Router
    def initialize(schema)
      @routes = build_routes(schema)
    end

    def routes?(method, path)
      if method_routes = @routes[method]
        method_routes.each do |pattern, link, schema|
          if path =~ pattern
            return link, schema
          end
        end
      end
      [nil, nil]
    end

    def routes_request?(request)
      routes?(request.request_method, request.path_info)
    end

    private

    def build_routes(schema)
      routes = {}
      schema.each do |_, type_schema|
        type_schema["links"].each do |link|
          routes[link["method"]] ||= []
          # /apps/{id} --> /apps/([^/]+)
          pattern = link["href"].gsub(/\{(.*?)\}/, "[^/]+")
          routes[link["method"]] <<
            [Regexp.new(pattern), link, type_schema]
        end
      end
      routes
    end
  end
end

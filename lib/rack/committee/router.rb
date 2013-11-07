module Rack::Committee
  class Router
    def initialize(schemata)
      @routes = build_routes(schemata)
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

    def build_routes(schemata)
      routes = {}
      schemata.each do |_, schema|
        schema["links"].each do |link|
          routes[link["method"]] ||= []
          # /apps/{id} --> /apps/([^/]+)
          pattern = link["href"].gsub(/\{(.*)\}/, "([^/]+)")
          routes[link["method"]] << [Regexp.new(pattern), link, schema]
        end
      end
      routes
    end
  end
end

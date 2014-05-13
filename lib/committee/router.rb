module Committee
  class Router
    def initialize(schema)
      @routes = build_routes(schema)
    end

    def routes?(method, path, options = {})
      path = path.gsub(/^#{options[:prefix]}/, "") if options[:prefix]
      if method_routes = @routes[method]
        method_routes.each do |pattern, link, schema|
          if path =~ pattern
            return link, schema
          end
        end
      end
      [nil, nil]
    end

    def routes_request?(request, options = {})
      routes?(request.request_method, request.path_info, options)
    end

    private

    def build_routes(schema)
      routes = {}
      # realistically, we should be examining links recursively at all levels
      schema.properties.each do |_, type_schema|
        type_schema.links.each do |link|
          method = link.method.to_s.upcase
          routes[method] ||= []
          # /apps/{id} --> /apps/([^/]+)
          href = link.href.gsub(/\{(.*?)\}/, "[^/]+")
          routes[method] << [%r{^#{href}$}, link, type_schema]
        end
      end
      routes
    end
  end
end

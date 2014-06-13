module Committee
  class Router
    def initialize(schema, options = {})
      @routes = build_routes(schema)
      @prefix = options[:prefix]
    end

    def routes?(method, path)
      path = path.gsub(/\A#{Regexp.escape(@prefix)}/, "") if @prefix
      if method_routes = @routes[method]
        method_routes.each do |pattern, link|
          if path =~ pattern
            return link
          end
        end
      end
      nil
    end

    def routes_request?(request)
      routes?(request.request_method, request.path_info)
    end

    private

    def build_routes(schema)
      routes = {}

      schema.links.each do |link|
        method, href = parse_link(link)
        next unless method
        routes[method] ||= []
        routes[method] << [%r{^#{href}$}, link]
      end

      # recursively iterate through all `properties` subschemas to build a
      # complete routing table
      schema.properties.each do |_, subschema|
        routes.merge!(build_routes(subschema)) { |_, r1, r2| r1 + r2 }
      end

      routes
    end

    def parse_link(link)
      return nil, nil if !link.method || !link.href
      method = link.method.to_s.upcase
      # /apps/{id} --> /apps/([^/]+)
      href = link.href.gsub(/\{(.*?)\}/, "[^/]+")
      [method, href]
    end
  end
end

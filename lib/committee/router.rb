module Committee
  class Router
    def initialize(schema, options = {})
      @prefix = options[:prefix]
      @prefix_regexp = /\A#{Regexp.escape(@prefix)}/.freeze if @prefix
      @schema = schema
    end

    def includes?(path)
      !@prefix || path =~ @prefix_regexp
    end

    def includes_request?(request)
      includes?(request.path)
    end

    def find_link(method, path)
      path = path.gsub(@prefix_regexp, "") if @prefix
      (@schema.routes[method] || []).map do |pattern, link|
        if matches = pattern.match(path)
          [link, Hash[matches.names.zip(matches.captures)]]
        else
          nil
        end
      end.compact.first
    end

    def find_request_link(request)
      find_link(request.request_method, request.path_info)
    end
  end
end

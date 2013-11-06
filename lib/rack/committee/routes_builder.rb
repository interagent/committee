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
  end
end

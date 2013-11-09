module Rack::Committee
  class Stub < Base
    def initialize(app, options={})
      super
      @cache = {}
    end

    def call(env)
      request = Rack::Request.new(env)
      link_schema, type_schema = @router.routes_request?(request)
      if type_schema
        str = cache(link_schema["method"], link_schema["href"]) do
          data = ResponseGenerator.new(@schema, type_schema, link_schema).call
          MultiJson.encode(data, pretty: true)
        end
        [200, { "Content-Type" => "application/json" }, [str]]
      else
        @app.call(env)
      end
    end

    private

    def cache(method, href)
      key = "#{method}+#{href}"
      if @cache[key]
        @cache[key]
      else
        @cache[key] = yield
      end
    end
  end
end

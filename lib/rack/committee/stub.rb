module Rack::Committee
  class Stub < Base
    def call(env)
      request = Rack::Request.new(env)
      _, type_schema = @router.routes_request?(request)
      if type_schema
        data = ResponseGenerator.new(schema, type_schema).call
        [200, {"Content-Type" => "application/json"}, [MultiJson.encode(data)]]
      else
        @app.call(env)
      end
    end
  end
end

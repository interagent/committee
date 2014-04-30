module Committee::Middleware
  class MemoryStub < Base
    def initialize(app, options={})
      super
      @memory = {}
      @call   = options[:call]
      @prefix = options[:prefix]
    end

    def call(env)
      request = Rack::Request.new(env)
      link_schema, type_schema = @router.routes_request?(request, prefix: @prefix)
      if type_schema
        headers = { "Content-Type" => "application/json" }

        data = case request.request_method
        when "GET"
          data = @memory[type_schema["id"]] || []
        end
        
        status = link_schema["rel"] == "create" ? 201 : 200
        [status, headers, [MultiJson.encode(data, pretty: true)]]
      else
        @app.call(env)
      end
    end
  end
end

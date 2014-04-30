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
        status  = 200

        data = case request.request_method
        when "GET"
          if link_schema["rel"] == "self"
            id_matcher = build_matcher(link_schema["href"])
            id = id_matcher.match(request.path_info)[1]
            if existing = fetch_resource(type_schema["id"], id)
              existing
            else
              status = 404
              {}
            end
          else
            list_resources(type_schema["id"])
          end
        when "POST"
        end
        
        status = 201 if link_schema["rel"] == "create"
        [status, headers, [MultiJson.encode(data, pretty: true)]]
      else
        @app.call(env)
      end
    end

    protected

    def list_resources(schema_id)
      (@memory[schema_id] || {}).values
    end

    def fetch_resource(schema_id, resource_id)
      (@memory[schema_id] || {})[resource_id]
    end

    # can only match a single id for now
    def build_matcher(href)
      Regexp.new(href.sub(/\{(.*)\}/, "([\\d\\w-]+)"))
    end

  end
end

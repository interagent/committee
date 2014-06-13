module Committee::Middleware
  class Stub < Base
    def initialize(app, options={})
      super
      @cache = {}
      @call   = options[:call]
    end

    def call(env)
      request = Rack::Request.new(env)
      if link = @router.routes_request?(request)
        headers = { "Content-Type" => "application/json" }
        data = cache(link.method, link.href) do
          Committee::ResponseGenerator.new.call(link)
        end
        if @call
          env["committee.response"] = data
          call_status, call_headers, call_body = @app.call(env)

          # a committee.suppress signal initiates a direct pass through
          if env["committee.suppress"] == true
            return call_status, call_headers, call_body
          end

          # otherwise keep the headers and whatever data manipulations were
          # made, and stub normally
          headers.merge!(call_headers)
        end
        status = link.rel == "create" ? 201 : 200
        [status, headers, [MultiJson.encode(data, pretty: true)]]
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

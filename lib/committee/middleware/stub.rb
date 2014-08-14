module Committee::Middleware
  class Stub < Base
    def initialize(app, options={})
      super
      @cache = {}
      @call  = options[:call]
    end

    def handle(request)
      if link = @router.find_request_link(request)
        headers = {
          "Content-Type" => "application/json",
          "Access-Control-Allow-Origin" => "*"
        }
        data = cache(link.method, link.href) do
          Committee::ResponseGenerator.new.call(link)
        end
        if @call
          request.env["committee.response"] = data
          call_status, call_headers, call_body = @app.call(request.env)

          # a committee.suppress signal initiates a direct pass through
          if request.env["committee.suppress"] == true
            return call_status, call_headers, call_body
          end

          # otherwise keep the headers and whatever data manipulations were
          # made, and stub normally
          headers.merge!(call_headers)
        end
        status = link.rel == "create" ? 201 : 200
        [status, headers, [MultiJson.encode(data, pretty: true)]]
      else
        @app.call(request.env)
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

module Committee::Middleware
  class Stub < Base
    def initialize(app, options={})
      super
      @cache = {}
      @call  = options[:call]
    end

    def handle(request)
      link, _ = @router.find_request_link(request)
      if link
        headers = { "Content-Type" => "application/json" }

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

          # allow allow the handler to change the data object (if unchanged, it
          # will be the same one that we set above)
          data = request.env["committee.response"]
        end

        [link.status_success, headers, [JSON.pretty_generate(data)]]
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

module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @prefix = options[:prefix]
    end

    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      link, _ =
        @router.routes_request?(request, prefix: @prefix)
      if link
        check_content_type!(headers)
        str = response.reduce("") { |str, s| str << s }
        Committee::ResponseValidator.new(link).call(MultiJson.decode(str))
      end
      [status, headers, response]
    rescue Committee::InvalidResponse
      render_error(500, :invalid_response, $!.message)
    rescue MultiJson::LoadError
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    end

    private

    def check_content_type!(headers)
      unless headers["Content-Type"] =~ %r{application/json}
        raise Committee::InvalidResponse,
          %{"Content-Type" response header must be set to "application/json".}
      end
    end
  end
end

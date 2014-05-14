module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @prefix = options[:prefix]
    end

    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      if link = @router.routes_request?(request, prefix: @prefix)
        check_content_type!(headers)
        str = response.reduce("") { |str, s| str << s }
        data = MultiJson.decode(str)
        Committee::ResponseValidator.new(link).call(data)
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

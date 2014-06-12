module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @prefix = options[:prefix]
      @raise  = options[:raise]
    end

    def call(env)
      status, headers, response = @app.call(env)
      request = Rack::Request.new(env)
      if link = @router.routes_request?(request, prefix: @prefix)
        str = response.reduce("") { |str, s| str << s }
        data = MultiJson.decode(str)
        Committee::ResponseValidator.new(link).call(headers, data)
      end
      [status, headers, response]
    rescue Committee::InvalidResponse
      raise if @raise
      render_error(500, :invalid_response, $!.message)
    rescue MultiJson::LoadError
      raise Committee::InvalidResponse if @raise
      render_error(500, :invalid_response, "Response wasn't valid JSON.")
    end
  end
end

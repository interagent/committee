module Committee::Middleware
  class ResponseValidation < Base
    def initialize(app, options={})
      super
      @raise  = options[:raise]
    end

    def handle(request)
      status, headers, response = @app.call(request.env)

      if link = @router.find_request_link(request)
        full_body = ""
        response.each do |chunk|
          full_body << chunk
        end
        data = MultiJson.decode(full_body)
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

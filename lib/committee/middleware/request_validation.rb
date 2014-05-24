module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super
      @prefix = options[:prefix]

      # deprecated
      @allow_extra = options[:allow_extra]
    end

    def call(env)
      request = Rack::Request.new(env)
      if link = @router.routes_request?(request, prefix: @prefix)
        validator = Committee::RequestValidator.new(link)
        validator.call(request)
        env[@params_key] = validator.data
      end
      @app.call(env)
    rescue Committee::BadRequest, Committee::InvalidRequest
      render_error(400, :bad_request, $!.message)
    rescue MultiJson::LoadError
      render_error(400, :bad_request, "Request body wasn't valid JSON.")
    end
  end
end

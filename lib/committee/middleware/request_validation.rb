module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super
      @allow_extra = options[:allow_extra]
      @prefix = options[:prefix]
    end

    def call(env)
      request = Rack::Request.new(env)
      env[@params_key] = Committee::RequestUnpacker.new(request).call
      link, _ = @router.routes_request?(request, prefix: @prefix)
      if link
        Committee::ParamValidator.new(
          env[@params_key],
          @schema,
          link,
          allow_extra: @allow_extra
        ).call
      end
      @app.call(env)
    rescue Committee::BadRequest => e
      render_error(400, :bad_request, e.message)
    rescue Committee::Error => e
      render_error(422, :invalid_params, e.message)
    rescue MultiJson::LoadError
      render_error(400, :invalid_params, "Request body wasn't valid JSON.")
    end
  end
end

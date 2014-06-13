module Committee::Middleware
  class RequestValidation < Base
    def initialize(app, options={})
      super
      @raise  = options[:raise]
      @strict = options[:strict]

      # deprecated
      @allow_extra = options[:allow_extra]
    end

    def handle(request)
      request.env[@params_key] = Committee::RequestUnpacker.new(request).call

      if link = @router.find_request_link(request)
        validator = Committee::RequestValidator.new(link)
        validator.call(request, request.env[@params_key])
        @app.call(request.env)
      elsif @strict
        raise Committee::NotFound
      else
        @app.call(request.env)
      end
    rescue Committee::BadRequest, Committee::InvalidRequest
      raise if @raise
      render_error(400, :bad_request, $!.message)
    rescue Committee::NotFound
      raise if @raise
      render_error(404, :not_found,
        "That request method and path combination isn't defined.")
    rescue MultiJson::LoadError
      raise Committee::InvalidRequest if @raise
      render_error(400, :bad_request, "Request body wasn't valid JSON.")
    end
  end
end

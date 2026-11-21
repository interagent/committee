# frozen_string_literal: true

module Committee
  class RequestUnpacker
    # Rack 1.5 uses standard exceptions; older Rack 2.x uses RangeError for depth limits.
    PARAMETER_ERRORS = if defined?(Rack::QueryParser)
                         [
                           Rack::QueryParser::ParameterTypeError,
                           Rack::QueryParser::InvalidParameterError,
                           defined?(Rack::QueryParser::ParamsTooDeepError) ? Rack::QueryParser::ParamsTooDeepError : RangeError,
                         ]
                       else
                         [TypeError, ArgumentError, RangeError]
                       end.freeze
    private_constant :PARAMETER_ERRORS

    class << self
      def parse_params
        yield
      rescue *PARAMETER_ERRORS => e
        raise Committee::BadRequest, e.message
      end

      # Enable string or symbol key access to the nested params hash.
      #
      # (Copied from Sinatra)
      def indifferent_params(object)
        case object
        when Hash
          new_hash = Committee::Utils.indifferent_hash
          object.each { |key, value| new_hash[key] = indifferent_params(value) }
          new_hash
        when Array
          object.map { |item| indifferent_params(item) }
        else
          object
        end
      end
    end

    def initialize(options = {})
      @allow_empty_date_and_datetime = options[:allow_empty_date_and_datetime]
      @allow_form_params             = options[:allow_form_params]
      @allow_get_body                = options[:allow_get_body]
      @allow_raw_body                = options[:allow_raw_body]
      @allow_json_array              = options[:allow_json_array]
      @allow_query_params            = options[:allow_query_params]
      @allow_non_get_query_params    = options[:allow_non_get_query_params]
      @optimistic_json               = options[:optimistic_json]
    end

    # return params and is_form_params
    def unpack_request_params(request)
      # if Content-Type is empty or JSON, and there was a request body, try to
      # interpret it as JSON
      json_body = !request.media_type || Committee::SchemaValidator.json_media_type?(request.media_type)
      params = if json_body
                 parse_json(request)
      elsif @optimistic_json
        begin
          parse_json(request)
        rescue JSON::ParserError
          nil
        end
      end

      return [params, false] if params

      form_body = %w[application/x-www-form-urlencoded multipart/form-data].include?(request.media_type)
      if @allow_form_params && form_body
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        begin
          params = self.class.parse_params { request.POST }
          return [params, true] if params
        ensure
          request.body.rewind if request.body.respond_to?(:rewind)
        end
      end

      if @allow_raw_body && !json_body && !form_body && (!request.get? || @allow_get_body)
        input = request.body
        body = input ? input.read : ""
        input.rewind if input.respond_to?(:rewind)
        return [body, false]
      end

      [{}, false]
    end

    def unpack_query_params(request)
      unless @allow_query_params
        return {}
      end

      params = self.class.parse_params do
        @allow_non_get_query_params ? request.params : request.GET
      ensure
        request.body.rewind if @allow_non_get_query_params && request.body.respond_to?(:rewind)
      end
      self.class.indifferent_params(params)
    end

    def unpack_headers(request)
      env = request.env
      base = env.keys.grep(/HTTP_/).inject({}) do |headers, key|
        headerized_key = key.gsub(/^HTTP_/, '').gsub(/_/, '-')
        headers[headerized_key] = env[key]
        headers
      end

      base['Content-Type'] = env['CONTENT_TYPE'] if env['CONTENT_TYPE']
      base
    end

    private

    def parse_json(request)
      return nil if request.request_method == "GET" && !@allow_get_body

      input = request.body
      return nil if input.nil?
      body = input.read
      # if request body is empty, we just have empty params
      return nil if body.length == 0

      input.rewind if input.respond_to?(:rewind)
      hash = JSON.parse(body)
      if !hash.is_a?(Hash) && !(@allow_json_array && hash.is_a?(Array))
        raise BadRequest, "Invalid JSON input. Require object with parameters as keys."
      end
      self.class.indifferent_params(hash)
    end
  end
end

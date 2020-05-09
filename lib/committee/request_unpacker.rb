# frozen_string_literal: true

module Committee
  class RequestUnpacker
    def initialize(request, options={})
      @request = request

      @allow_form_params  = options[:allow_form_params]
      @allow_get_body     = options[:allow_get_body]
      @allow_query_params = options[:allow_query_params]
      @coerce_form_params = options[:coerce_form_params]
      @optimistic_json    = options[:optimistic_json]
      @schema_validator   = options[:schema_validator]
    end

    def call
      return call_hyperschema if hyperschema?

      # if Content-Type is empty or JSON, and there was a request body, try to
      # interpret it as JSON
      params = {}

      params['body'] = if !@request.media_type || @request.media_type =~ %r{application/.*json}
        parse_json
      elsif @optimistic_json
        begin
          parse_json
        rescue JSON::ParserError
          nil
        end
      else
        {}
      end

      params['form_data'] = if @allow_form_params && %w[application/x-www-form-urlencoded multipart/form-data].include?(@request.media_type)
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        p = @request.POST

        @schema_validator.coerce_form_params(p) if @coerce_form_params

        p
      else
        {}
      end

      params['query'] = if @allow_query_params
        indifferent_params(@request.GET)
      else
        {}
      end

      [params, headers]
    end

    private

    def call_hyperschema
      # if Content-Type is empty or JSON, and there was a request body, try to
      # interpret it as JSON
      params = if !@request.media_type || @request.media_type =~ %r{application/.*json}
        parse_json
      elsif @optimistic_json
        begin
          parse_json
        rescue JSON::ParserError
          nil
        end
      end

      params = if params
        params
      elsif @allow_form_params && %w[application/x-www-form-urlencoded multipart/form-data].include?(@request.media_type)
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        p = @request.POST

        @schema_validator.coerce_form_params(p) if @coerce_form_params

        p
      else
        {}
      end

      if @allow_query_params
        [indifferent_params(@request.GET).merge(params), headers]
      else
        [params, headers]
      end
    end

    # Creates a Hash with indifferent access.
    #
    # (Copied from Sinatra)
    def indifferent_hash
      Hash.new { |hash,key| hash[key.to_s] if Symbol === key }
    end

    def hyperschema?
      @schema_validator.is_a?(Committee::SchemaValidator::HyperSchema)
    end

    # Enable string or symbol key access to the nested params hash.
    #
    # (Copied from Sinatra)
    def indifferent_params(object)
      case object
      when Hash
        new_hash = indifferent_hash
        object.each { |key, value| new_hash[key] = indifferent_params(value) }
        new_hash
      when Array
        object.map { |item| indifferent_params(item) }
      else
        object
      end
    end

    def parse_json
      return nil if @request.request_method == "GET" && !@allow_get_body

      body = @request.body.read
      # if request body is empty, we just have empty params
      return nil if body.length == 0

      @request.body.rewind
      hash = JSON.parse(body)
      # We want a hash specifically. '42', 42, and [42] will all be
      # decoded properly, but we can't use them here.
      if !hash.is_a?(Hash)
        raise BadRequest,
              "Invalid JSON input. Require object with parameters as keys."
      end
      indifferent_params(hash)
    end

    def headers
      env = @request.env
      base = env.keys.grep(/HTTP_/).inject({}) do |headers, key|
        headerized_key = key.gsub(/^HTTP_/, '').gsub(/_/, '-')
        headers[headerized_key] = env[key]
        headers
      end

      base['Content-Type'] = env['CONTENT_TYPE'] if env['CONTENT_TYPE']
      base
    end
  end
end

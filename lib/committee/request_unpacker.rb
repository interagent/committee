# frozen_string_literal: true

module Committee
  class RequestUnpacker
    class << self
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

    def initialize(options={})
      @allow_form_params  = options[:allow_form_params]
      @allow_get_body     = options[:allow_get_body]
      @allow_query_params = options[:allow_query_params]
      @optimistic_json    = options[:optimistic_json]
    end

    # return params and is_form_params
    def unpack_request_params(request)
      # if Content-Type is empty or JSON, and there was a request body, try to
      # interpret it as JSON
      params = if !request.media_type || request.media_type =~ %r{application/(?:.*\+)?json}
        parse_json(request)
      elsif @optimistic_json
        begin
          parse_json(request)
        rescue JSON::ParserError
          nil
        end
      end

      return [params, false] if params

      if @allow_form_params && %w[application/x-www-form-urlencoded multipart/form-data].include?(request.media_type)
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        return [request.POST, true] if request.POST
      end

      [{}, false]
    end

    def unpack_query_params(request)
      @allow_query_params ? self.class.indifferent_params(request.GET) : {}
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

      body = request.body.read
      # if request body is empty, we just have empty params
      return nil if body.length == 0

      request.body.rewind
      hash = JSON.parse(body)
      # We want a hash specifically. '42', 42, and [42] will all be
      # decoded properly, but we can't use them here.
      if !hash.is_a?(Hash)
        raise BadRequest,
              "Invalid JSON input. Require object with parameters as keys."
      end
      self.class.indifferent_params(hash)
    end
  end
end

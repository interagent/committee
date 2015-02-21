module Committee
  class RequestUnpacker
    def initialize(request, options={})
      @request = request

      @allow_form_params  = options[:allow_form_params]
      @allow_query_params = options[:allow_query_params]
      @optimistic_json    = options[:optimistic_json]
    end

    def call
      # if Content-Type is empty or JSON, and there was a request body, try to
      # interpret it as JSON
      params = if !@request.content_type || @request.content_type =~ %r{application/.*json}
        parse_json
      elsif @optimistic_json
        parse_json rescue MultiJson::LoadError nil
      end

      params = if params
        params
      elsif @allow_form_params && @request.content_type == "application/x-www-form-urlencoded"
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        indifferent_params(@request.POST)
      else
        {}
      end

      if @allow_query_params
        indifferent_params(@request.GET).merge(params)
      else
        params
      end
    end

    private

    # Creates a Hash with indifferent access.
    #
    # (Copied from Sinatra)
    def indifferent_hash
      Hash.new { |hash,key| hash[key.to_s] if Symbol === key }
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
      if (body = @request.body.read).length != 0
        @request.body.rewind
        hash = MultiJson.decode(body)
        # We want a hash specifically. '42', 42, and [42] will all be
        # decoded properly, but we can't use them here.
        if !hash.is_a?(Hash)
          raise BadRequest,
            "Invalid JSON input. Require object with parameters as keys."
        end
        indifferent_params(hash)
      # if request body is empty, we just have empty params
      else
        nil
      end
    end
  end
end

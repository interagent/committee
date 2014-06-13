module Committee
  class RequestUnpacker
    def initialize(request)
      @request = request
    end

    def call
      if !@request.content_type || @request.content_type =~ %r{application/json}
        # if Content-Type is empty or JSON, and there was a request body, try
        # to interpret it as JSON
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
          {}
        end
      elsif @request.content_type == "application/x-www-form-urlencoded"
        # Actually, POST means anything in the request body, could be from
        # PUT or PATCH too. Silly Rack.
        indifferent_params(@request.POST)
      else
        {}
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
  end
end

require "multi_json"

module Rack
  class Committee
    class BadRequest < StandardError
    end

    class InvalidParams < StandardError
    end

    class ParamValidator
      def initialize(params, link_schema)
        @params = params
        @link_schema = link_schema
      end

      def call
        detect_missing!
        detect_extra!
      end

      private

      def detect_extra!
        extra = @params.keys - @link_schema["schema"]["properties"].keys
        if extra.count > 0
          raise InvalidParams.new("Unknown params: #{missing.join(', ')}.")
        end
      end

      def detect_missing!
        missing = @link_schema["schema"]["required"] - @params.keys
        if missing.count > 0
          raise InvalidParams.new("Require params: #{missing.join(', ')}.")
        end
      end
    end

    class RequestUnpacker
      def initialize(env)
        @request = Rack::Request.new(env)
      end

      def call
        if !@request.content_type || @request.content_type == "application/json"
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
          raise BadRequest, "Unsupported Content-Type: #{@request.content_type}."
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

    class RoutesBuilder
      def initialize(schemata)
        @schemata = schemata
      end

      def call
        routes = {}
        @schemata.each do |_, schema|
          schema["links"].each do |link|
            routes[link["method"]] ||= []
            # /apps/{id} --> /apps/([^/]+)
            pattern = link["href"].gsub(/\{(.*)\}/, "([^/]+)")
            routes[link["method"]] << [Regexp.new(pattern), link]
          end
        end
        routes
      end
    end

    def initialize(app, options={})
      @app = app

      blobs = options[:schema] || raise("need option `schema`")
      blobs = [blobs] if !blobs.is_a?(Array)
      @params_key = options[:params_key] || "committee.params"

      @schemata = {}
      blobs.map { |b| MultiJson.decode(b) }.each do |schema|
        @schemata[schema["id"]] = schema
      end
      @routes = RoutesBuilder.new(@schemata).call
    end

    def call(env)
      env[@params_key] = RequestUnpacker.new(env).call
      if method_routes = @routes[env["REQUEST_METHOD"]]
        method_routes.each do |pattern, link|
          if env["PATH_INFO"] =~ pattern
            ParamValidator.new(env[@params_key], link).call
          end
        end
      end
      @app.call(env)
    rescue BadRequest
      [400, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: :bad_request, error: $!.message)]]
    end
  end
end

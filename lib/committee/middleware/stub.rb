# frozen_string_literal: true

# Stub is not yet supported in OpenAPI 3

module Committee
  module Middleware
    class Stub < Base
      def initialize(app, options={})
        super

        # A bug in Committee's cache implementation meant that it wasn't working
        # for a very long time, even for people who thought they were taking
        # advantage of it. I repaired the caching feature, but have disable it by
        # default so that we don't need to introduce any class-level variables
        # that could have memory leaking implications. To enable caching, just
        # pass an empty hash to this option.
        @cache = options[:cache]

        @call = options[:call]

        raise Committee::OpenAPI3Unsupported.new("Stubs are not yet supported for OpenAPI 3") unless @schema.supports_stub?
      end

      def handle(request)
        link, _ = @router.find_request_link(request)
        if link
          headers = { "Content-Type" => "application/json" }

          data, schema = cache(link) do
            Committee::SchemaValidator::HyperSchema::ResponseGenerator.new.call(link)
          end

          if @call
            request.env["committee.response"] = data
            request.env["committee.response_schema"] = schema
            call_status, call_headers, call_body = @app.call(request.env)

            # a committee.suppress signal initiates a direct pass through
            if request.env["committee.suppress"] == true
              return call_status, call_headers, call_body
            end

            # otherwise keep the headers and whatever data manipulations were
            # made, and stub normally
            headers.merge!(call_headers)

            # allow the handler to change the data object (if unchanged, it
            # will be the same one that we set above)
            data = request.env["committee.response"]
          end

          [link.status_success, headers, [JSON.pretty_generate(data)]]
        else
          @app.call(request.env)
        end
      end

      private

      def cache(link)
        return yield unless @cache

        # Just the object ID is enough to uniquely identify the link, but store
        # the method and href so that we can more easily introspect the cache if
        # necessary.
        key = "#{link.object_id}##{link.method}+#{link.href}"
        if @cache[key]
          @cache[key]
        else
          @cache[key] = yield
        end
      end
    end
  end
end

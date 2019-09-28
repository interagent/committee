# frozen_string_literal: true

module Committee
  module Drivers
    # Schema is a base class for driver schema implementations.
    class Schema
      # A link back to the derivative instance of Committee::Drivers::Driver
      # that create this schema.
      def driver
        raise "needs implementation"
      end

      def build_router(options)
        raise "needs implementation"
      end

      # Stubs are supported in JSON Hyper-Schema and OpenAPI 2, but not yet in OpenAPI 3
      def supports_stub?
        true
      end
    end
  end
end

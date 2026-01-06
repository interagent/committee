# frozen_string_literal: true

module Committee
  module Middleware
    module Options
      class ResponseValidation < Base
        # ResponseValidation specific options
        attr_reader :strict
        attr_reader :validate_success_only
        attr_reader :parse_response_by_content_type
        attr_reader :coerce_response_values
        attr_reader :streaming_content_parsers

        # Default values
        DEFAULTS = { strict: false, validate_success_only: true, parse_response_by_content_type: true, coerce_response_values: false }.freeze

        def initialize(options = {})
          super(options)

          # Validation related
          @strict = options.fetch(:strict, DEFAULTS[:strict])
          @validate_success_only = options.fetch(:validate_success_only, DEFAULTS[:validate_success_only])
          @parse_response_by_content_type = options.fetch(:parse_response_by_content_type, DEFAULTS[:parse_response_by_content_type])
          @coerce_response_values = options.fetch(:coerce_response_values, DEFAULTS[:coerce_response_values])

          # Streaming
          @streaming_content_parsers = options[:streaming_content_parsers] || {}

          validate_response_validation_options!
        end

        private

        def validate_response_validation_options!
          return if @streaming_content_parsers.is_a?(Hash)

          raise ArgumentError, "streaming_content_parsers must be a Hash"
        end

        def build_hash
          super.merge(strict: @strict, validate_success_only: @validate_success_only, parse_response_by_content_type: @parse_response_by_content_type, coerce_response_values: @coerce_response_values, streaming_content_parsers: @streaming_content_parsers)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Committee
  module Middleware
    module Options
      class Base
        # Common options
        attr_reader :schema
        attr_reader :schema_path
        attr_reader :error_class
        attr_reader :error_handler
        attr_reader :raise_error
        attr_reader :ignore_error
        attr_reader :prefix
        attr_reader :accept_request_filter

        # Schema loading options
        attr_reader :strict_reference_validation

        def initialize(options = {})
          @original_options = options.dup.freeze

          # Schema related
          @schema = options[:schema]
          @schema_path = options[:schema_path]
          @strict_reference_validation = options.fetch(:strict_reference_validation, false)

          # Error handling
          @error_class = options.fetch(:error_class, Committee::ValidationError)
          @error_handler = options[:error_handler]
          @raise_error = options[:raise] || false
          @ignore_error = options.fetch(:ignore_error, false)

          # Routing
          @prefix = options[:prefix]
          @accept_request_filter = options[:accept_request_filter] || ->(_) { true }

          validate!
        end

        # Allow Hash-like access for backward compatibility
        def [](key)
          to_h[key]
        end

        def fetch(key, default = nil)
          to_h.fetch(key, default)
        end

        def to_h
          @to_h ||= build_hash
        end

        # Create an Option object from Hash options
        # Returns the object as-is if already an Option object
        def self.from(options)
          case options
          when self
            options
          when Hash
            new(options)
          else
            raise ArgumentError, "options must be a Hash or #{name}"
          end
        end

        private

        def validate!
          validate_error_class!
          validate_error_handler!
          validate_schema_source!
          validate_accept_request_filter!
        end

        def validate_error_handler!
          return if @error_handler.nil? || @error_handler.respond_to?(:call)

          raise ArgumentError, "error_handler must respond to #call"
        end

        def validate_error_class!
          return if @error_class.is_a?(Class)

          raise ArgumentError, "error_class must be a Class"
        end

        def validate_schema_source!
          return if @schema || @schema_path

          raise ArgumentError, "Committee: need option `schema` or `schema_path`"
        end

        def validate_accept_request_filter!
          return if @accept_request_filter.respond_to?(:call)

          raise ArgumentError, "accept_request_filter must respond to #call"
        end

        def build_hash
          # Start with original options to preserve any options not explicitly handled
          @original_options.dup.merge(schema: @schema, schema_path: @schema_path, strict_reference_validation: @strict_reference_validation, error_class: @error_class, error_handler: @error_handler, raise: @raise_error, ignore_error: @ignore_error, prefix: @prefix, accept_request_filter: @accept_request_filter)
        end
      end
    end
  end
end

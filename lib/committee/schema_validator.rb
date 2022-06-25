# frozen_string_literal: true

module Committee
  module SchemaValidator
    class << self
      def request_media_type(request)
        request.media_type.to_s
      end

      # @param [String] prefix
      # @return [Regexp]
      def build_prefix_regexp(prefix)
        return nil unless prefix

        /\A#{Regexp.escape(prefix)}/.freeze
      end
    end
  end
end

require_relative "schema_validator/hyper_schema"
require_relative "schema_validator/open_api_3"
require_relative "schema_validator/option"

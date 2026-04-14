# frozen_string_literal: true

module Committee
  module SchemaValidator
    JSON_MEDIA_TYPE_PATTERN = %r{\Aapplication/(?:.+\+)?json\z}.freeze

    class << self
      def request_media_type(request)
        Rack::MediaType.type(request.env['CONTENT_TYPE'])
      end

      def json_media_type?(content_type)
        normalized_content_type = Rack::MediaType.type(content_type)
        normalized_content_type&.match?(JSON_MEDIA_TYPE_PATTERN) || false
      end

      # @param [String] prefix
      # @return [Regexp]
      def build_prefix_regexp(prefix)
        return nil unless prefix

        if prefix == "/" || prefix.end_with?("/")
          /\A#{Regexp.escape(prefix)}/.freeze
        else
          /\A#{Regexp.escape(prefix)}(?=\/|\z)/.freeze
        end
      end
    end
  end
end

require_relative "schema_validator/hyper_schema"
require_relative "schema_validator/open_api_3"
require_relative "schema_validator/option"

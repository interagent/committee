# frozen_string_literal: true

module Committee
  module SchemaValidator
    JSON_MEDIA_TYPE_PATTERN = %r{\Aapplication/(?:.+\+)?json\z}.freeze
    SEQUENTIAL_JSON_MEDIA_TYPE_PATTERN = %r{\A(?:application/(?:jsonl|x-ndjson|json-seq)|[^/]+/[^/]+\+json-seq)\z}.freeze

    class << self
      def request_media_type(request)
        Rack::MediaType.type(request.env['CONTENT_TYPE'])
      end

      def json_media_type?(content_type)
        normalized_content_type = Rack::MediaType.type(content_type)
        normalized_content_type&.match?(JSON_MEDIA_TYPE_PATTERN) || false
      end

      def sequential_json_media_type?(content_type)
        Rack::MediaType.type(content_type)&.match?(SEQUENTIAL_JSON_MEDIA_TYPE_PATTERN) || false
      end

      def parse_sequential_json(body, content_type)
        unless Rack::MediaType.type(content_type).end_with?('json-seq')
          return body.each_line("\n").map { |line| JSON.parse(line) }
        end

        unless body.empty? || body.start_with?("\x1e")
          raise JSON::ParserError, 'JSON sequence must start with a record separator'
        end

        body.split("\x1e").reject(&:empty?).map do |record|
          value = JSON.parse(record)
          # RFC 7464 requires trailing whitespace to detect truncated numbers and literals.
          case value
          when Numeric, TrueClass, FalseClass, NilClass
            raise JSON::ParserError, 'JSON sequence scalar is not terminated by whitespace' unless record.match?(/[ \t\r\n]\z/)
          end
          value
        end
      end

      # @param [String] prefix
      # @return [Regexp]
      def build_prefix_regexp(prefix)
        return nil unless prefix

        /\A#{Regexp.escape(prefix.chomp("/"))}(?=\/|\z)/.freeze
      end
    end
  end
end

require_relative "schema_validator/hyper_schema"
require_relative "schema_validator/open_api_3"
require_relative "schema_validator/option"

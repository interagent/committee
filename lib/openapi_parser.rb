require 'uri'
require 'time'
require 'json'
require 'psych'
require 'pathname'
require 'open-uri'

require 'openapi_parser/version'
require 'openapi_parser/config'
require 'openapi_parser/errors'
require 'openapi_parser/concern'
require 'openapi_parser/schemas'
require 'openapi_parser/path_item_finder'
require 'openapi_parser/request_operation'
require 'openapi_parser/schema_validator'
require 'openapi_parser/parameter_validator'
require 'openapi_parser/reference_expander'

module OpenAPIParser
  class << self
    # Load schema yaml object. Uri is not set for returned schema.
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def parse(schema, config = {})
      load_hash(schema, config: Config.new(config), uri: nil, schema_registry: {})
    end

    # Load schema in specified filepath. If file path is relative, it is resolved using working directory.
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def load(filepath, config = {})
      path = Pathname.new(filepath)
      path = Pathname.getwd + path if path.relative?
      load_uri(URI::File.build(path: path.to_s), config: Config.new(config), schema_registry: {})
    end

    # Load schema located by the passed uri. Uri must be absolute.
    # @return [OpenAPIParser::Schemas::OpenAPI]
    def load_uri(uri, config:, schema_registry:)
      # Open-uri doesn't open file scheme uri, so we try to open file path directly
      # File scheme uri which points to a remote file is not supported.
      content = if uri.scheme == 'file'
        open(uri.path, &:read)
      else
        uri.open(&:read)
      end

      extension = Pathname.new(uri.path).extname
      load_hash(parse_file(content, extension), config: config, uri: uri, schema_registry: schema_registry)
    end

    private

      def parse_file(content, extension)
        case extension.downcase
        when '.yaml', '.yml'
          parse_yaml(content)
        when '.json'
          parse_json(content)
        else
          # When extension is something we don't know, try to parse as json first. If it fails, parse as yaml
          begin
            parse_json(content)
          rescue JSON::ParserError
            parse_yaml(content)
          end
        end
      end

      def parse_yaml(content)
        Psych.safe_load(content)
      end

      def parse_json(content)
        JSON.parse(content)
      end

      def load_hash(hash, config:, uri:, schema_registry:)
        root = Schemas::OpenAPI.new(hash, config, uri: uri, schema_registry: schema_registry)

        OpenAPIParser::ReferenceExpander.expand(root) if config.expand_reference

        root
      end
  end
end

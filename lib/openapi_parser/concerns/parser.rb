module OpenAPIParser::Parser
end

require_relative './parser/core'
require_relative './schema_loader'

module OpenAPIParser::Parser
  def self.included(base)
    base.extend(ClassMethods)
  end
  module ClassMethods
    extend Forwardable

    def_delegators :_parser_core, :_openapi_attr_values, :openapi_attr_value, :openapi_attr_values
    def_delegators :_parser_core, :_openapi_attr_objects, :openapi_attr_objects, :openapi_attr_object
    def_delegators :_parser_core, :_openapi_attr_list_objects, :openapi_attr_list_object
    def_delegators :_parser_core, :_openapi_attr_hash_objects, :openapi_attr_hash_object
    def_delegators :_parser_core, :_openapi_attr_hash_body_objects, :openapi_attr_hash_body_objects

    def _parser_core
      @_parser_core ||= OpenAPIParser::Parser::Core.new(self)
    end
  end

  # @param [OpenAPIParser::Schemas::Base] old
  # @param [OpenAPIParser::Schemas::Base] new
  def _update_child_object(old, new)
    _openapi_all_child_objects[old.object_reference] = new
  end

  # @return [Hash{String => OpenAPIParser::Schemas::Base}]
  def _openapi_all_child_objects
    @_openapi_all_child_objects ||= {}
  end

  def load_data
    loader = ::OpenAPIParser::SchemaLoader.new(self, self.class._parser_core)
    loader.load_data

    @_openapi_all_child_objects = loader.children
  end
end

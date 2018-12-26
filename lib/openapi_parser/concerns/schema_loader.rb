class OpenAPIParser::SchemaLoader
end

require_relative './schema_loader/base'
require_relative './schema_loader/values_loader'
require_relative './schema_loader/list_loader'
require_relative './schema_loader/objects_loader'
require_relative './schema_loader/hash_objects_loader'
require_relative './schema_loader/hash_body_loader'

class OpenAPIParser::SchemaLoader
  attr_reader :children

  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [OpenAPIParser::Parser::Core] core
  def initialize(target_object, core)
    @target_object = target_object
    @core = core
    @children = {}
  end

  def load_data
    OpenAPIParser::SchemaLoader::ValuesLoader.new(self).create_attr_values(core._openapi_attr_values)
    OpenAPIParser::SchemaLoader::ObjectsLoader.new(self).create_attr_objects(core._openapi_attr_objects)
    OpenAPIParser::SchemaLoader::ListLoader.new(self).create_attr_list_objects(core._openapi_attr_list_objects)
    OpenAPIParser::SchemaLoader::HashObjectsLoader.new(self).create_attr_hash_objects(core._openapi_attr_hash_objects)
    OpenAPIParser::SchemaLoader::HashBodyLoader.new(self).create_attr_hash_body_objects(core._openapi_attr_hash_body_objects)
  end

  def register_child(object)
    return unless object.kind_of?(OpenAPIParser::Parser)

    @children[object.object_reference] = object
  end

  attr_reader :target_object, :core
end

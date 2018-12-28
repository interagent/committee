class OpenAPIParser::SchemaLoader
end

require_relative './schema_loader/base'
require_relative './schema_loader/creator'
require_relative './schema_loader/values_loader'
require_relative './schema_loader/list_loader'
require_relative './schema_loader/objects_loader'
require_relative './schema_loader/hash_objects_loader'
require_relative './schema_loader/hash_body_loader'

# load data to target_object by schema definition in core
class OpenAPIParser::SchemaLoader
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [OpenAPIParser::Parser::Core] core
  def initialize(target_object, core)
    @target_object = target_object
    @core = core
    @children = {}
  end

  # @!attribute [r] children
  #   @return [Array<OpenAPIParser::Schemas::Base>]
  attr_reader :children

  # execute load data
  # return data is equal to :children
  # @return [Array<OpenAPIParser::Schemas::Base>]
  def load_data
    all_loader.each { |l| load_data_by_schema_loader(l) }
    children
  end

  private

    attr_reader :core, :target_object

    # @param [OpenAPIParser::SchemaLoader::Base] schema_loader
    def load_data_by_schema_loader(schema_loader)
      children = schema_loader.load_data(target_object, target_object.raw_schema)

      children.each { |c| register_child(c) } if children
    end

    def register_child(object)
      return unless object.kind_of?(OpenAPIParser::Parser)

      @children[object.object_reference] = object
    end

    def all_loader
      core._openapi_attr_values.values +
        core._openapi_attr_objects.values +
        core._openapi_attr_list_objects.values +
        core._openapi_attr_hash_objects.values +
        core._openapi_attr_hash_body_objects.values
    end
end

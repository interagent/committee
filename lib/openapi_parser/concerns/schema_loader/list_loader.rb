# list object loader
class OpenAPIParser::SchemaLoader::ListLoader < OpenAPIParser::SchemaLoader::Creator
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(target_object, raw_schema)
    create_attr_list_object(target_object, raw_schema[ref_name_base.to_s])
  end

  private

    def create_attr_list_object(target_object, array_schema)
      unless array_schema
        variable_set(target_object, variable_name, nil)
        return
      end

      data = array_schema.map.with_index do |s, idx|
        ref = build_object_reference_from_base(target_object.object_reference, [ref_name_base, idx])
        build_openapi_object_from_option(target_object, ref, s)
      end

      variable_set(target_object, variable_name, data)
      data
    end

    alias_method :ref_name_base, :schema_key
end

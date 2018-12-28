# hash object loader
class OpenAPIParser::SchemaLoader::HashObjectsLoader < OpenAPIParser::SchemaLoader::Creator
  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(target_object, raw_schema)
    create_attr_hash_object(target_object, raw_schema[ref_name_base.to_s])
  end

  private

    def create_attr_hash_object(target_object, hash_schema)
      unless hash_schema
        variable_set(target_object, variable_name, nil)
        return
      end

      data_list = hash_schema.map do |key, s|
        ref = build_object_reference_from_base(target_object.object_reference, [ref_name_base, key])
        [key, build_openapi_object_from_option(target_object, ref, s)]
      end

      data = data_list.to_h
      variable_set(target_object, variable_name, data)
      data.values
    end

    alias_method :ref_name_base, :schema_key
end

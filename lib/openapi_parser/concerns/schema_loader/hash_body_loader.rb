# hash body object loader
class OpenAPIParser::SchemaLoader::HashBodyLoader < OpenAPIParser::SchemaLoader::Creator
  # @param [String] variable_name
  # @param [Hash] options
  def initialize(variable_name, options)
    super(variable_name, options)

    @reject_keys = options[:reject_keys] ? options[:reject_keys].map(&:to_s) : []
  end

  # @param [OpenAPIParser::Schemas::Base] target_object
  # @param [Hash] raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(target_object, raw_schema)
    # raw schema always exist because if not exist' this object don't create
    create_hash_body_objects(target_object, raw_schema)
  end

  private

    # for responses and paths object
    def create_hash_body_objects(target_object, raw_schema)
      object_list = raw_schema.reject { |k, _| reject_keys.include?(k) }.map do |child_name, child_schema|
        ref = build_object_reference_from_base(target_object.object_reference, escape_reference(child_name))
        [
          child_name.to_s, # support string key only in OpenAPI3
          build_openapi_object_from_option(target_object, ref, child_schema),
        ]
      end

      objects = object_list.to_h
      variable_set(target_object, variable_name, objects)
      objects.values
    end

    attr_reader :reject_keys
end

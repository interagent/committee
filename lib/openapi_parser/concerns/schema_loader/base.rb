# loader base class
class OpenAPIParser::SchemaLoader::Base
  # @param [String] variable_name
  # @param [Hash] options
  def initialize(variable_name, options)
    @variable_name = variable_name
    @schema_key = options[:schema_key] || variable_name
  end

  # @param [OpenAPIParser::Schemas::Base] _target_object
  # @param [Hash] _raw_schema
  # @return [Array<OpenAPIParser::Schemas::Base>, nil]
  def load_data(_target_object, _raw_schema)
    raise 'need implement'
  end

  private

    attr_reader :variable_name, :schema_key

    # create instance variable @variable_name using data
    # @param [OpenAPIParser::Schemas::Base] target
    # @param [String] variable_name
    # @param [Object] data
    def variable_set(target, variable_name, data)
      target.instance_variable_set("@#{variable_name}", data)
    end
end

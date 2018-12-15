class OpenAPIParser::SchemaValidator
  class << self
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas::Schema]
    def validate(value, schema)
      new(value, schema).validate_data
    end
  end

  # @param [Hash] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def initialize(value, schema)
    @value = value
    @schema = schema
  end

  def validate_data
    err = validate_schema(@value, @schema)
    raise err if err
    nil
  end

  private

  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_schema(value, schema)
    return unless schema
    return validate_any_of(value, schema) if schema.any_of

    if value.nil?
      return if schema.nullable
      return OpenAPIParser::NotNullError.new(schema.object_reference)
    end

    case schema.type
    when "string"
      return validate_string(value, schema) if value.is_a?(String)
    when "integer"
      return validate_integer(value, schema) if value.is_a?(Integer)
    when "boolean"
      return if value.is_a?(TrueClass)
      return if value.is_a?(FalseClass)
    when "number"
      return validate_integer(value, schema) if value.is_a?(Integer)
      return validate_number(value, schema) if value.is_a?(Numeric)
    when "object"
      return validate_object(value, schema) if value.is_a?(Hash)
    when "array"
      return validate_array(value, schema) if value.is_a?(Array)
    else
      # TODO: unknown type support
    end

    OpenAPIParser::ValidateError.new(value, schema.type, schema.object_reference)
  end

  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_any_of(value, schema)
    # in all schema return error (=true) not any of data
    schema.any_of.all? { |s| validate_schema(value, s) } ? OpenAPIParser::NotAnyOf.new(value, schema.object_reference) : nil
  end

  def validate_string(value, schema)
    check_enum_include(value, schema)
  end

  def validate_integer(value, schema)
    check_enum_include(value, schema)
  end

  def validate_number(value, schema)
    check_enum_include(value, schema)
  end

  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def check_enum_include(value, schema)
    return unless schema.enum
    return if schema.enum.include?(value)

    OpenAPIParser::NotEnumInclude.new(value, schema.object_reference)
  end

  # @param [Hash] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_object(value, schema)
    return unless schema.properties
    required_set = schema.required ? schema.required.to_set : Set.new

    value.each do |name, v|
      s = schema.properties[name]
      err = validate_schema(v, s)
      return err if err

      required_set.delete(name)
    end

    return OpenAPIParser::NotExistRequiredKey.new(required_set.to_a, schema.object_reference) unless required_set.empty?
    nil
  end

  # @param [Array] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_array(value, schema)
    # array type have an schema in items property
    items_schema = schema.items

    value.each do |v|
      err = validate_schema(v, items_schema)
      return err if err
    end

    nil
  end
end

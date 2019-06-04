# loader base class for create OpenAPI::Schemas::Base object
class OpenAPIParser::SchemaLoader::Creator < OpenAPIParser::SchemaLoader::Base
  # @param [String] variable_name
  # @param [Hash] options
  def initialize(variable_name, options)
    super(variable_name, options)

    @klass = options[:klass]
    @allow_reference = options[:reference] || false
    @allow_data_type = options[:allow_data_type]
  end

  private

    attr_reader :klass, :allow_reference, :allow_data_type

    def build_object_reference_from_base(base, names)
      names = [names] unless names.kind_of?(Array)
      ref = names.map { |n| escape_reference(n) }.join('/')

      "#{base}/#{ref}"
    end

    # @return Boolean
    def check_reference_schema?(check_schema)
      check_object_schema?(check_schema) && !check_schema['$ref'].nil?
    end

    def check_object_schema?(check_schema)
      check_schema.kind_of?(::Hash)
    end

    def escape_reference(str)
      str.to_s.gsub('/', '~1')
    end

    def build_openapi_object_from_option(target_object, ref, schema)
      return nil if schema.nil?

      if @allow_data_type && !check_object_schema?(schema)
        schema
      elsif @allow_reference && check_reference_schema?(schema)
        OpenAPIParser::Schemas::Reference.new(ref, target_object, target_object.root, schema)
      else
        @klass.new(ref, target_object, target_object.root, schema)
      end
    end
end

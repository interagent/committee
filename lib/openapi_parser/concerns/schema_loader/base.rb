class OpenAPIParser::SchemaLoader::Base
  # @param [OpenAPIParser::SchemaLoader] loader
  def initialize(loader)
    @loader = loader
  end

  private

    def register_child_to_loader(child)
      @loader.register_child(child)
    end

    def target_object
      @loader.target_object
    end

    def raw_schema
      target_object.raw_schema
    end

    def object_reference
      target_object.object_reference
    end

    # create instance variable @variable_name using data
    # @param [String] variable_name
    # @param [Object] data
    def create_variable(variable_name, data)
      target_object.instance_variable_set("@#{variable_name}", data)
    end

    # @return [String]
    def build_object_reference(names)
      names = [names] unless names.kind_of?(Array)
      ref = names.map { |n| escape_reference(n) }.join('/')

      "#{object_reference}/#{ref}"
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

    # return nil, klass, Reference
    def build_openapi_object(ref_names, schema, klass, allow_reference, allow_data_type)
      return nil unless schema

      if allow_data_type && !check_object_schema?(schema)
        schema
      elsif allow_reference && check_reference_schema?(schema)
        OpenAPIParser::Schemas::Reference.new(build_object_reference(ref_names), target_object, target_object.root, schema)
      else
        klass.new(build_object_reference(ref_names), target_object, target_object.root, schema)
      end
    end
end

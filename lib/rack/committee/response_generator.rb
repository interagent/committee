module Rack::Committee
  class ResponseGenerator
    def initialize(schema, type_schema, link_schema)
      @schema = schema
      @type_schema = type_schema
      @link_schema = link_schema
    end

    def call
      generate_properties(@type_schema)
    end

    private

    def generate_properties(schema)
      data = {}
      schema["properties"].each do |name, value|
        data[name] = if value["properties"]
          generate_properties(value)
        else
          definition = @schema.find(value["$ref"])
          definition["example"]
        end
      end
      # list is a special case; wrap data in an array
      data = [data] if @link_schema["title"] == "List"
      data
    end
  end
end

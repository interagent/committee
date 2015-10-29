module Committee
  class ResponseGenerator
    def call(link)
      data = generate_properties(link.target_schema || link.parent)

      # list is a special case; wrap data in an array
      data = [data] if link.rel == "instances"

      data
    end

    private

    def generate_properties(schema)
      # special example attribute was included; use its value
      if !schema.data["example"].nil?
        schema.data["example"]
      # null is allowed; use that
      elsif schema.type.include?("null")
        nil
      elsif schema.type.include?("array") && !schema.items.nil?
        [generate_properties(schema.items)]
      elsif !schema.properties.empty?
        data = {}
        schema.properties.map do |key, value|
          data[key] = generate_properties(value)
        end
        data
      else
        raise(%{At "#{schema.pointer}": no "example" attribute and "null" } +
          %{is not allowed; don't know how to generate property.})
      end
    end
  end
end

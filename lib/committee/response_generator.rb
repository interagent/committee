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
      data = {}
      schema.properties.each do |key, value|
        data[key] = if !value.properties.empty?
          generate_properties(value)
        else
          # special example attribute was included; use its value
          if !value.data["example"].nil?
            value.data["example"]
          # null is allowed; use that
          elsif value.type.include?("null")
            nil
          # otherwise we don't know what to do (we could eventually generate
          # random data based on type/format
          else
            raise(%{At "#{schema.id}"/"#{key}": no "example" attribute and "null" is not allowed; don't know how to generate property.})
          end
        end
      end
      data
    end
  end
end

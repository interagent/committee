# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      class ResponseGenerator
        def call(link)
          schema = target_schema(link)
          data = generate_properties(link, schema)

          # List is a special case; wrap data in an array.
          #
          # This is poor form that's here so as not to introduce breaking behavior.
          # The "instances" value of "rel" is a Heroku-ism and was originally
          # introduced before we understood how to use "targetSchema". It's not
          # meaningful with the context of the hyper-schema specification and
          # should be eventually be removed.
          if legacy_hyper_schema_rel?(link)
            data = [data]
          end

          [data, schema]
        end

        private

        # These are basic types that are part of the JSON schema for which we'll
        # emit zero values when generating a response. For a schema that allows
        # multiple of the types in the list, types are preferred in the order in
        # which they're defined.
        SCALAR_TYPES = {
          "boolean" => false,
          "integer" => 0,
          "number"  => 0.0,
          "string"  => "",

          # Prefer null last.
          "null" => nil,
        }.freeze

        def generate_properties(link, schema)
          # special example attribute was included; use its value
          if schema.data && !schema.data["example"].nil?
            schema.data["example"]

          elsif !schema.all_of.empty? || !schema.properties.empty?
            data = {}
            schema.all_of.each do |subschema|
              data.merge!(generate_properties(link, subschema))
            end
            schema.properties.map do |key, value|
              data[key] = generate_properties(link, value)
            end
            data

          elsif schema.type.include?("array") && !schema.items.nil?
            [generate_properties(link, schema.items)]

          elsif schema.enum
            schema.enum.first

          elsif schema.type.any? { |t| SCALAR_TYPES.include?(t) }
            SCALAR_TYPES.each do |k, v|
              break(v) if schema.type.include?(k)
            end

          # Generate an empty array for arrays.
          elsif schema.type == ["array"]
            []

          # Schema is an object with no properties: just generate an empty object.
          elsif schema.type == ["object"]
            {}

          else
            raise(%{At "#{link.method} #{link.href}" "#{schema.pointer}": no } +
              %{"example" attribute and "null" } +
              %{is not allowed; don't know how to generate property.})
          end
        end

        def legacy_hyper_schema_rel?(link)
          link.is_a?(Committee::Drivers::HyperSchema::Link) &&
            link.rel == "instances" &&
            !link.target_schema
        end

        # Gets the target schema of a link. This is normally just the standard
        # response schema, but we allow some legacy behavior for hyper-schema links
        # tagged with rel=instances to instead use the schema of their parent
        # resource.
        def target_schema(link)
          if link.target_schema
            link.target_schema
          elsif legacy_hyper_schema_rel?(link)
            link.parent
          end
        end
      end
    end
  end
end

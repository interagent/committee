# TODO: support 'not' because I need check reference...
# TODO: support 'xml', 'externalDocs'
# TODO: support extended property

module OpenAPIParser::Schemas
  class Schema < Base
    # @!attribute [r] title
    #   @return [String, nil]
    # @!attribute [r] pattern
    #   @return [String, nil] regexp
    # @!attribute [r] pattern
    #   @return [String, nil] regexp
    # @!attribute [r] description
    #   @return [String, nil]
    # @!attribute [r] format
    #   @return [String, nil]
    # @!attribute [r] type
    #   @return [String, nil] multiple types doesn't supported in OpenAPI3

    # @!attribute [r] maximum
    #   @return [Float, nil]
    # @!attribute [r] multipleOf
    #   @return [Float, nil]

    # @!attribute [r] maxLength
    #   @return [Integer, nil]
    # @!attribute [r] minLength
    #   @return [Integer, nil]
    # @!attribute [r] maxItems
    #   @return [Integer, nil]
    # @!attribute [r] minItems
    #   @return [Integer, nil]
    # @!attribute [r] maxProperties
    #   @return [Integer, nil]
    # @!attribute [r] minProperties
    #   @return [Integer, nil]

    # @!attribute [r] exclusiveMaximum
    #   @return [Boolean, nil]
    # @!attribute [r] exclusiveMinimum
    #   @return [Boolean, nil]
    # @!attribute [r] uniqueItems
    #   @return [Boolean, nil]
    # @!attribute [r] nullable
    #   @return [Boolean, nil]
    # @!attribute [r] deprecated
    #   @return [Boolean, nil]

    # @!attribute [r] required
    #   @return [Array<String>, nil] at least one item included

    # @!attribute [r] enum
    #   @return [Array, nil] any type array

    # @!attribute [r] default
    #   @return [Object, nil]

    # @!attribute [r] example
    #   @return [Object, nil]

    openapi_attr_values :title, :multipleOf,
                        :maximum, :exclusiveMaximum, :minimum, :exclusiveMinimum,
                        :maxLength, :minLength,
                        :pattern,
                        :maxItems, :minItems, :uniqueItems,
                        :maxProperties, :minProperties,
                        :required, :enum,
                        :description,
                        :format,
                        :default,
                        :type,
                        :nullable,
                        :example,
                        :deprecated

    # @!attribute [r] read_only
    #   @return [Boolean, nil]
    openapi_attr_value :read_only, schema_key: :readOnly

    # @!attribute [r] write_only
    #   @return [Boolean, nil]
    openapi_attr_value :write_only, schema_key: :writeOnly

    # @!attribute [r] all_of
    #   @return [Array<Schema, Reference>, nil]
    openapi_attr_list_object :all_of, Schema, reference: true, schema_key: :allOf

    # @!attribute [r] one_of
    #   @return [Array<Schema, Reference>, nil]
    openapi_attr_list_object :one_of, Schema, reference: true, schema_key: :oneOf

    # @!attribute [r] any_of
    #   @return [Array<Schema, Reference>, nil]
    openapi_attr_list_object :any_of, Schema, reference: true, schema_key: :anyOf

    # @!attribute [r] items
    #   @return [Schema, nil]
    openapi_attr_object :items, Schema, reference: true

    # @!attribute [r] properties
    #   @return [Hash{String => Schema}, nil]
    openapi_attr_hash_object :properties, Schema, reference: true

    # @!attribute [r] discriminator
    #   @return [Discriminator, nil]
    openapi_attr_object :discriminator, Discriminator

    # @!attribute [r] additional_properties
    #   @return [Boolean, Schema, Reference, nil]
    openapi_attr_object :additional_properties, Schema, reference: true, allow_data_type: true, schema_key: :additionalProperties
    # additional_properties have default value
    # we should add default value feature in openapi_attr_object method, but we need temporary fix so override attr_reader
    def additional_properties
      @additional_properties.nil? ? true : @additional_properties
    end
  end
end

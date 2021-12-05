# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI2
      # ParameterSchemaBuilder converts OpenAPI 2 link parameters, which are not
      # quite JSON schemas (but will be in OpenAPI 3) into synthetic schemas that
      # we can use to do some basic request validation.
      class ParameterSchemaBuilder < SchemaBuilder
        # Returns a tuple of (schema, schema_data) where only one of the two
        # values is present. This is either a full schema that's ready to go _or_
        # a hash of unparsed schema data.
        def call
          if link_data["parameters"]
            body_param = link_data["parameters"].detect { |p| p["in"] == "body" }
            if body_param
              check_required_fields!(body_param)

              if link_data["parameters"].detect { |p| p["in"] == "form" } != nil
                raise ArgumentError, "Committee: can't mix body parameter " \
                  "with form parameters."
              end

              schema_data = body_param["schema"]
              [nil, schema_data]
            else
              link_schema = JsonSchema::Schema.new
              link_schema.properties = {}
              link_schema.required = []

              parameters = link_data["parameters"].reject { |param_data| param_data["in"] == "header" }
              parameters.each do |param_data|
                check_required_fields!(param_data)

                param_schema = JsonSchema::Schema.new

                # We could probably use more validation here, but the formats of
                # OpenAPI 2 are based off of what's available in JSON schema, and
                # therefore this should map over quite well.
                param_schema.type = [param_data["type"]]

                param_schema.enum = param_data["enum"] unless param_data["enum"].nil?

                # validation: string
                param_schema.format = param_data["format"] unless param_data["format"].nil?
                param_schema.pattern = Regexp.new(param_data["pattern"]) unless param_data["pattern"].nil?
                param_schema.min_length = param_data["minLength"] unless param_data["minLength"].nil?
                param_schema.max_length = param_data["maxLength"] unless param_data["maxLength"].nil?

                # validation: array
                param_schema.min_items = param_data["minItems"] unless param_data["minItems"].nil?
                param_schema.max_items = param_data["maxItems"] unless param_data["maxItems"].nil?
                param_schema.unique_items = param_data["uniqueItems"] unless param_data["uniqueItems"].nil?

                # validation: number/integer
                param_schema.min = param_data["minimum"] unless param_data["minimum"].nil?
                param_schema.min_exclusive = param_data["exclusiveMinimum"] unless param_data["exclusiveMinimum"].nil?
                param_schema.max = param_data["maximum"] unless param_data["maximum"].nil?
                param_schema.max_exclusive = param_data["exclusiveMaximum"] unless param_data["exclusiveMaximum"].nil?
                param_schema.multiple_of = param_data["multipleOf"] unless param_data["multipleOf"].nil?

                # And same idea: despite parameters not being schemas, the items
                # key (if preset) is actually a schema that defines each item of an
                # array type, so we can just reflect that directly onto our
                # artificial schema.
                if param_data["type"] == "array" && param_data["items"]
                  param_schema.items = param_data["items"]
                end

                link_schema.properties[param_data["name"]] = param_schema
                if param_data["required"] == true
                  link_schema.required << param_data["name"]
                end
              end

              [link_schema, nil]
            end
          end
        end
      end
    end
  end
end

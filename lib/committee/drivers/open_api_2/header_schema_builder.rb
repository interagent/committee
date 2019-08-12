# frozen_string_literal: true

module Committee
  module Drivers
    module OpenAPI2
      class HeaderSchemaBuilder < SchemaBuilder
        def call
          if link_data["parameters"]
            link_schema = JsonSchema::Schema.new
            link_schema.properties = {}
            link_schema.required = []

            header_parameters = link_data["parameters"].select { |param_data| param_data["in"] == "header" }
            header_parameters.each do |param_data|
              check_required_fields!(param_data)

              param_schema = JsonSchema::Schema.new

              param_schema.type = [param_data["type"]]

              link_schema.properties[param_data["name"]] = param_schema
              if param_data["required"] == true
                link_schema.required << param_data["name"]
              end
            end

            link_schema
          end
        end
      end
    end
  end
end

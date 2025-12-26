# frozen_string_literal: true

require 'set'

module Committee
  module SchemaValidator
    class OpenAPI3
      # Deserializes request parameters based on OpenAPI 3 parameter style and explode settings
      #
      # @see https://swagger.io/docs/specification/serialization/
      # @see https://spec.openapis.org/oas/latest.html#parameter-object
      class ParameterDeserializer
        # @param [OpenAPIParser::RequestOperation] request_operation
        def initialize(request_operation)
          @request_operation = request_operation
          @parameters = request_operation.operation_object.parameters || []
        end

        # Deserialize query parameters
        # @param [Hash] raw_params Raw query parameters from Rack
        # @return [Hash] Deserialized parameters according to OpenAPI schema
        def deserialize_query_params(raw_params)
          deserialize_params_by_location(raw_params, 'query')
        end

        # Deserialize path parameters
        # @param [Hash] raw_params Raw path parameters
        # @return [Hash] Deserialized parameters according to OpenAPI schema
        def deserialize_path_params(raw_params)
          deserialize_params_by_location(raw_params, 'path')
        end

        # Deserialize header parameters
        # @param [Hash] raw_headers Raw headers
        # @return [Hash] Deserialized headers according to OpenAPI schema
        def deserialize_headers(raw_headers)
          deserialize_params_by_location(raw_headers, 'header')
        end

        private

        # Deserialize parameters for a specific location (query, path, header)
        # @param [Hash] raw_params Raw parameters
        # @param [String] location Parameter location ('query', 'path', 'header')
        # @return [Hash] Deserialized parameters
        def deserialize_params_by_location(raw_params, location)
          return raw_params if raw_params.nil? || raw_params.empty?

          result = Committee::Utils.indifferent_hash
          params_for_location = @parameters.select { |p| p.in == location }

          # If no parameters are defined for this location, return raw params as-is
          return raw_params if params_for_location.empty?

          # Collect parameter names that will be deserialized
          # This includes both the parameter name and any properties (for exploded objects)
          deserialized_keys = Set.new

          # Deserialize each parameter defined in the schema
          params_for_location.each do |param_def|
            value = extract_and_deserialize(param_def, raw_params)

            # Only include non-nil values
            if !value.nil?
              # For objects, ensure the result is also an indifferent hash
              value = convert_to_indifferent_hash(value) if value.is_a?(Hash)

              result[param_def.name] = value
              deserialized_keys.add(param_def.name)

              # For form-style exploded objects, mark the property keys as deserialized
              if param_def.schema&.type == 'object' &&
                 (param_def.style.nil? || param_def.style == 'form') &&
                 (param_def.explode.nil? || param_def.explode)
                param_def.schema.properties&.each_key do |prop_name|
                  deserialized_keys.add(prop_name)
                  deserialized_keys.add(prop_name.to_s)
                end
              end

              # For deep object style, mark the bracket-notation keys as deserialized
              if param_def.style == 'deepObject'
                prefix = "#{param_def.name}["
                raw_params.each_key do |key|
                  key_str = key.to_s
                  deserialized_keys.add(key) if key_str.start_with?(prefix)
                end
              end
            end
          end

          # Include params not in schema (for additionalProperties and unknown params)
          # Only include params that weren't consumed by deserialization
          raw_params.each do |key, value|
            result[key] = value unless deserialized_keys.include?(key)
          end

          result
        end

        # Convert a hash to an indifferent hash (supports both string and symbol keys)
        # @param [Hash] hash
        # @return [Committee::Utils::IndifferentHash]
        def convert_to_indifferent_hash(hash)
          return hash unless hash.is_a?(Hash)
          Committee::Utils.indifferent_hash.merge(hash)
        end

        # Extract and deserialize a single parameter
        # @param [OpenAPIParser::Schemas::Parameter] param_def Parameter definition
        # @param [Hash] raw_params Raw parameters
        # @return [Object] Deserialized value
        def extract_and_deserialize(param_def, raw_params)
          style = param_def.style || default_style(param_def.in)
          explode = param_def.explode.nil? ? default_explode(style) : param_def.explode

          case style
          when 'form'
            deserialize_form_style(param_def, raw_params, explode)
          when 'simple'
            deserialize_simple_style(param_def, raw_params, explode)
          when 'label'
            deserialize_label_style(param_def, raw_params, explode)
          when 'matrix'
            deserialize_matrix_style(param_def, raw_params, explode)
          when 'spaceDelimited'
            deserialize_space_delimited(param_def, raw_params, explode)
          when 'pipeDelimited'
            deserialize_pipe_delimited(param_def, raw_params, explode)
          when 'deepObject'
            deserialize_deep_object(param_def, raw_params)
          else
            # Unsupported style - return raw value
            raw_params[param_def.name]
          end
        rescue StandardError => e
          raise Committee::ParameterDeserializationError.new(param_def.name, style, raw_params[param_def.name], e.message)
        end

        # Get default style for a parameter location
        # @param [String] location Parameter location
        # @return [String] Default style
        def default_style(location)
          case location
          when 'query', 'cookie'
            'form'
          when 'path', 'header'
            'simple'
          else
            'form'
          end
        end

        # Get default explode setting for a style
        # @param [String] style Parameter style
        # @return [Boolean] Default explode value
        def default_explode(style)
          style == 'form'
        end

        # Deserialize form style parameter
        # Default for query and cookie parameters
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Object] Deserialized value
        def deserialize_form_style(param_def, raw_params, explode)
          param_name = param_def.name
          schema = param_def.schema
          return nil unless schema

          case schema.type
          when 'object'
            deserialize_form_object(param_name, schema, raw_params, explode)
          when 'array'
            deserialize_form_array(param_name, schema, raw_params, explode)
          else
            # Primitive type - just return the value
            raw_params[param_name]
          end
        end

        # Deserialize form-style object
        # @param [String] param_name
        # @param [OpenAPIParser::Schemas::Schema] schema
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Hash, nil] Deserialized object
        def deserialize_form_object(param_name, schema, raw_params, explode)
          if explode
            # explode=true: object properties are separate parameters
            # Example: ?role=admin&status=active → { role: "admin", status: "active" }
            collect_object_properties(schema, raw_params, param_name)
          else
            # explode=false: comma-separated key,value pairs
            # Example: ?id=role,admin,status,active → { role: "admin", status: "active" }
            value = raw_params[param_name]
            value ? parse_comma_separated_object(value) : nil
          end
        end

        # Deserialize form-style array
        # @param [String] param_name
        # @param [OpenAPIParser::Schemas::Schema] schema
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Array, nil] Deserialized array
        def deserialize_form_array(param_name, schema, raw_params, explode)
          value = raw_params[param_name]
          return nil unless value

          if explode
            # explode=true: Rack already collects ?id=1&id=2 into an array
            # Just ensure it's an array
            Array(value)
          else
            # explode=false: comma-separated values
            # Example: ?id=1,2,3 → ["1", "2", "3"]
            value.is_a?(String) ? value.split(',') : Array(value)
          end
        end

        # Collect object properties from separate parameters (form explode=true)
        # @param [OpenAPIParser::Schemas::Schema] schema
        # @param [Hash] raw_params
        # @param [String] param_name Original parameter name (not used in exploded form)
        # @return [Hash, nil] Collected object properties
        def collect_object_properties(schema, raw_params, param_name)
          result = Committee::Utils.indifferent_hash
          properties = schema.properties || {}

          properties.each do |prop_name, prop_schema|
            # Look for property directly in raw_params (exploded form)
            if raw_params.key?(prop_name)
              result[prop_name] = raw_params[prop_name]
            elsif raw_params.key?(prop_name.to_s)
              result[prop_name] = raw_params[prop_name.to_s]
            end
          end

          result.empty? ? nil : result
        end

        # Parse comma-separated object (form explode=false)
        # Example: "role,admin,status,active" → { "role" => "admin", "status" => "active" }
        # @param [String] value Comma-separated string
        # @return [Hash] Parsed object
        def parse_comma_separated_object(value)
          parts = value.split(',')
          result = Committee::Utils.indifferent_hash

          # Parts should be in key,value,key,value format
          (0...parts.length).step(2) do |i|
            break if i + 1 >= parts.length
            result[parts[i]] = parts[i + 1]
          end

          result
        end

        # Deserialize deep object style (query parameters only)
        # Example: ?filter[role]=admin&filter[status]=active → { filter: { role: "admin", status: "active" } }
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @return [Hash, nil] Deserialized object
        def deserialize_deep_object(param_def, raw_params)
          param_name = param_def.name
          prefix = "#{param_name}["
          result = Committee::Utils.indifferent_hash

          raw_params.each do |key, value|
            key_str = key.to_s
            if key_str.start_with?(prefix) && key_str.end_with?(']')
              property_name = key_str[prefix.length...-1]
              result[property_name] = value
            end
          end

          result.empty? ? nil : result
        end

        # Deserialize simple style (path and header parameters)
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Object] Deserialized value
        def deserialize_simple_style(param_def, raw_params, explode)
          param_name = param_def.name
          value = raw_params[param_name]
          return nil unless value

          schema = param_def.schema
          return value unless schema

          case schema.type
          when 'array'
            # Both explode true/false use comma separation for simple style
            # Example: "1,2,3" → ["1", "2", "3"]
            value.is_a?(String) ? value.split(',') : Array(value)
          when 'object'
            if explode
              # explode=true: key=value,key2=value2
              parse_key_value_pairs(value, ',', '=')
            else
              # explode=false: key,value,key2,value2
              parse_comma_separated_object(value)
            end
          else
            value
          end
        end

        # Deserialize label style (path parameters)
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Object] Deserialized value
        def deserialize_label_style(param_def, raw_params, explode)
          param_name = param_def.name
          value = raw_params[param_name]
          return nil unless value

          # Remove leading dot
          value = value[1..-1] if value.start_with?('.')

          schema = param_def.schema
          return value unless schema

          case schema.type
          when 'array'
            if explode
              # explode=true: .3.4.5 → ["3", "4", "5"]
              value.split('.')
            else
              # explode=false: .3,4,5 → ["3", "4", "5"]
              value.split(',')
            end
          when 'object'
            if explode
              # explode=true: .role=admin.status=active
              parse_key_value_pairs(value, '.', '=')
            else
              # explode=false: .role,admin,status,active
              parse_comma_separated_object(value)
            end
          else
            value
          end
        end

        # Deserialize matrix style (path parameters)
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Object] Deserialized value
        def deserialize_matrix_style(param_def, raw_params, explode)
          param_name = param_def.name
          value = raw_params[param_name]
          return nil unless value

          schema = param_def.schema
          return value unless schema

          case schema.type
          when 'array'
            if explode
              # explode=true: ;id=3;id=4 (multiple occurrences)
              # Rack should have already collected these into an array
              Array(value)
            else
              # explode=false: ;id=3,4,5
              extract_matrix_array_compact(value, param_name)
            end
          when 'object'
            if explode
              # explode=true: ;role=admin;status=active
              extract_matrix_object_exploded(value, param_name)
            else
              # explode=false: ;id=role,admin,status,active
              extract_matrix_object_compact(value, param_name)
            end
          else
            # Primitive: ;id=5
            extract_matrix_primitive(value, param_name)
          end
        end

        # Extract matrix-style array (explode=false)
        # @param [String] value Matrix-style string
        # @param [String] param_name Parameter name
        # @return [Array] Extracted array
        def extract_matrix_array_compact(value, param_name)
          # ;id=3,4,5 → ["3", "4", "5"]
          prefix = ";#{param_name}="
          if value.start_with?(prefix)
            value[prefix.length..-1].split(',')
          else
            []
          end
        end

        # Extract matrix-style object (explode=true)
        # @param [String] value Matrix-style string
        # @param [String] param_name Parameter name
        # @return [Hash] Extracted object
        def extract_matrix_object_exploded(value, param_name)
          # ;role=admin;status=active → { "role" => "admin", "status" => "active" }
          result = Committee::Utils.indifferent_hash
          pairs = value.split(';').reject(&:empty?)

          pairs.each do |pair|
            next unless pair.include?('=')
            key, val = pair.split('=', 2)
            result[key] = val
          end

          result
        end

        # Extract matrix-style object (explode=false)
        # @param [String] value Matrix-style string
        # @param [String] param_name Parameter name
        # @return [Hash] Extracted object
        def extract_matrix_object_compact(value, param_name)
          # ;id=role,admin,status,active → { "role" => "admin", "status" => "active" }
          prefix = ";#{param_name}="
          if value.start_with?(prefix)
            parse_comma_separated_object(value[prefix.length..-1])
          else
            {}
          end
        end

        # Extract matrix-style primitive value
        # @param [String] value Matrix-style string
        # @param [String] param_name Parameter name
        # @return [String] Extracted value
        def extract_matrix_primitive(value, param_name)
          # ;id=5 → "5"
          prefix = ";#{param_name}="
          if value.start_with?(prefix)
            value[prefix.length..-1]
          else
            value
          end
        end

        # Deserialize space-delimited style (query parameters, arrays only)
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Array, nil] Deserialized array
        def deserialize_space_delimited(param_def, raw_params, explode)
          param_name = param_def.name
          value = raw_params[param_name]
          return nil unless value

          # Example: "1 2 3" or "1%202%203" → ["1", "2", "3"]
          value.is_a?(String) ? value.split(' ') : Array(value)
        end

        # Deserialize pipe-delimited style (query parameters, arrays only)
        # @param [OpenAPIParser::Schemas::Parameter] param_def
        # @param [Hash] raw_params
        # @param [Boolean] explode
        # @return [Array, nil] Deserialized array
        def deserialize_pipe_delimited(param_def, raw_params, explode)
          param_name = param_def.name
          value = raw_params[param_name]
          return nil unless value

          # Example: "1|2|3" → ["1", "2", "3"]
          value.is_a?(String) ? value.split('|') : Array(value)
        end

        # Parse key-value pairs with custom delimiters
        # @param [String] value String containing key-value pairs
        # @param [String] pair_delimiter Delimiter between pairs
        # @param [String] kv_delimiter Delimiter between key and value
        # @return [Hash] Parsed object
        def parse_key_value_pairs(value, pair_delimiter, kv_delimiter)
          result = Committee::Utils.indifferent_hash
          pairs = value.split(pair_delimiter).reject(&:empty?)

          pairs.each do |pair|
            next unless pair.include?(kv_delimiter)
            key, val = pair.split(kv_delimiter, 2)
            result[key] = val
          end

          result
        end
      end
    end
  end
end

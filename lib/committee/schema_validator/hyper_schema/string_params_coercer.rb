# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      # StringParamsCoercer takes parameters that are specified over a medium that
      # can only accept strings (for example in a URL path or in query parameters)
      # and attempts to coerce them into known types based of a link's schema
      # definition.
      #
      # Currently supported types: null, integer, number and boolean.
      #
      # +call+ returns a hash of all params which could be coerced - coercion
      # errors are simply ignored and expected to be handled later by schema
      # validation.
      class StringParamsCoercer
        def initialize(query_hash, schema, options = {})
          @query_hash = query_hash
          @schema = schema

          @coerce_recursive = options.fetch(:coerce_recursive, false)
        end

        def call!
          coerce_object!(@query_hash, @schema)
        end

        private

          def coerce_object!(hash, schema)
            return false unless schema.respond_to?(:properties)

            is_coerced = false
            schema.properties.each do |k, s|
              original_val = hash[k]
              unless original_val.nil?
                new_value, is_changed = coerce_value!(original_val, s)
                if is_changed
                  hash[k] = new_value
                  is_coerced = true
                end
              end
            end

            is_coerced
          end

          def coerce_value!(original_val, s)
            unless original_val.nil?
              s.type.each do |to_type|
                case to_type
                  when "null"
                    return nil, true if original_val.empty?
                  when "integer"
                    begin
                      return Integer(original_val), true
                    rescue ArgumentError => e
                      raise e unless e.message =~ /invalid value for Integer/
                    end
                  when "number"
                    begin
                      return Float(original_val), true
                    rescue ArgumentError => e
                      raise e unless e.message =~ /invalid value for Float/
                    end
                  when "boolean"
                    if original_val == "true" || original_val == "1"
                      return true, true
                    end
                    if original_val == "false" || original_val == "0"
                      return false, true
                    end
                  when "array"
                    if @coerce_recursive && coerce_array_data!(original_val, s)
                      return original_val, true # change original value
                    end
                  when "object"
                    if @coerce_recursive && coerce_object!(original_val, s)
                      return original_val, true # change original value
                    end
                end
              end
            end
            return nil, false
          end

          def coerce_array_data!(original_val, schema)
            return false unless schema.respond_to?(:items)
            return false unless original_val.is_a?(Array)

            is_coerced = false
            original_val.each_with_index do |d, index|
              new_value, is_changed = coerce_value!(d, schema.items)
              if is_changed
                original_val[index] = new_value
                is_coerced = true
              end
            end

            is_coerced
          end
      end
    end
  end
end

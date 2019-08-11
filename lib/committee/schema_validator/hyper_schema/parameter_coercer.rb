# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      class ParameterCoercer
        def initialize(params, schema, options = {})
          @params = params
          @schema = schema

          @coerce_date_times = options.fetch(:coerce_date_times, false)
          @coerce_recursive = options.fetch(:coerce_recursive, false)
        end

        def call!
          coerce_object!(@params, @schema)
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
            s.type.each do |to_type|
              if @coerce_date_times && to_type == "string" && s.format == "date-time"
                coerced_val = parse_date_time(original_val)
                return coerced_val, true if coerced_val
              end

              return original_val, true if @coerce_recursive && (to_type == "array") && coerce_array_data!(original_val, s)

              return original_val, true if @coerce_recursive && (to_type == "object") && coerce_object!(original_val, s)
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

          def parse_date_time(original_val)
            begin
              DateTime.parse(original_val)
            rescue ArgumentError => e
              raise ::Committee::InvalidResponse unless e.message =~ /invalid date/
            end
          end
      end
    end
  end
end

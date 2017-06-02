module Committee
  class ParameterCoercer
    def initialize(params, schema, options = {})
      @params = params
      @schema = schema

      @coerce_date_times = options.fetch(:coerce_date_times, false)
      @coerce_recursive = options.fetch(:coerce_recursive, false)
    end

    def call!
      return {} unless @schema.respond_to?(:properties)

      coercer_value!(@params, @schema.properties)
    end

    private

      def coercer_value!(params, properties)
        is_coerce = false

        properties.each do |k, s|
          original_val = params[k]

          unless original_val.nil?
            s.type.each do |to_type|
              if @coerce_date_times && to_type == "string" && s.format == "date-time"
                coerce_val = parse_date_time(original_val)

                if coerce_val
                  params[k] = coerce_val
                  is_coerce = true
                  break
                end
              end

              if (@coerce_recursive && to_type == "array") || (@coerce_recursive && to_type == "object")
                if coerce_data_recursive!(original_val, to_type, s)
                  is_coerce = true
                  break
                end
              end
            end
          end
        end

        is_coerce
      end

      def coerce_data_recursive!(original_val, to_type, schema)
        return coerce_array_data!(original_val, schema) if to_type == "array"
        return coerce_object_data!(original_val, schema) if to_type == "object"
        nil # bug?
      end

      def coerce_object_data!(original_val, schema)
        return false unless schema.respond_to?(:properties)

        coercer_value!(original_val, schema.properties)
      end

      def coerce_array_data!(original_val, schema)
        return false unless schema.respond_to?(:items)
        return false unless original_val.is_a?(Array)

        is_coerce = false
        original_val.each do |d|
          is_coerce = coercer_value!(d, schema.items.properties)
        end

        is_coerce
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

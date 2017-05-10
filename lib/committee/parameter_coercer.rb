module Committee
  class ParameterCoercer
    def initialize(params, schema, options = {})
      @params = params
      @schema = schema

      @coerce_date_times = options.fetch(:coerce_date_times, false)
      @coerce_recursive = options.fetch(:coerce_recursive, false)
    end

    def call
      return {} unless @schema.respond_to?(:properties)

      coercer_value(@params, @schema.properties)
    end

    private

      def coercer_value(params, properties)
        coerced = {}

        properties.each do |k, s|
          original_val = params[k]

          unless original_val.nil?
            s.type.each do |to_type|
              if @coerce_date_times && to_type == "string" && s.format == "date-time"
                coerce_val = parse_date_time(original_val)
                coerced[k] = coerce_val if coerce_val
              end

              if (@coerce_recursive && to_type == "array") || (@coerce_recursive && to_type == "object")
                coerce_val = coerce_data_recursive(original_val, to_type, s)
                coerced[k] = coerce_val unless coerce_val.empty?
              end

              break if coerced.key?(k)
            end
          end
        end

        coerced
      end

      def coerce_data_recursive(original_val, to_type, schema)
        return coerce_array_data(original_val, schema) if to_type == "array"
        return coerce_object_data(original_val, schema) if to_type == "object"
        nil # bug?
      end

      def coerce_object_data(original_val, schema)
        return {} unless schema.respond_to?(:properties)

        coerce_val = coercer_value(original_val, schema.properties)
        original_val.merge(coerce_val)
      end

      def coerce_array_data(original_val, schema)
        return [] unless schema.respond_to?(:items)
        return [] unless original_val.is_a?(Array)

        is_coerced = false
        coerced_array = []
        original_val.each do |d|
          coerced = coercer_value(d, schema.items.properties)

          is_coerced =  true unless coerced.empty?
          coerced_array << d.merge(coerced)
        end

        return [] unless is_coerced # did't coerce
        coerced_array
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

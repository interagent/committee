module Committee
  class ParameterCoercer
    def initialize(params, schema, options = {})
      @params = params
      @schema = schema

      @coerce_date_times = options.fetch(:coerce_date_times, false)
    end

    def call
      coerced = {}
      return coerced unless @schema.respond_to?(:properties)

      @schema.properties.each do |k, s|
        original_val = @params[k]

        unless original_val.nil?
          s.type.each do |to_type|
            if @coerce_date_times && to_type == "string" && s.format == "date-time"
              coerce_val = parse_date_time(original_val)
              coerced[k] = coerce_val if coerce_val
            end

            break if coerced.key?(k)
          end
        end
      end

      coerced
    end

    private
      def parse_date_time(original_val)
        begin
          DateTime.parse(original_val)
        rescue ArgumentError => e
          raise ::Committee::InvalidResponse unless e.message =~ /invalid date/
        end
      end
  end
end

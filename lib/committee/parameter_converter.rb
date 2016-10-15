module Committee
  class ParameterConverter
    def initialize(params, schema)
      @params = params
      @schema = schema
    end

    def convert!
      coerced = {}
      @schema.properties.each do |k, s|
        original_val = @params[k]

        unless original_val.nil?
          s.type.each do |to_type|
            case to_type
            when "string"
              coerce_val = coerce_string_val(original_val, s)
              coerced[k] = coerce_val if coerce_val
            end

            break if coerced.key?(k)
          end
        end
      end

      coerced
    end

    private

      def coerce_string_val(original_val, scheme)
        case scheme.format
          when "date-time"
            begin
              DateTime.parse(original_val)
            rescue ArgumentError => e
              raise e unless e.message =~ /invalid date/
            end
          else
            nil
        end
      end
  end
end

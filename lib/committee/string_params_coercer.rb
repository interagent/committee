module Committee
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
    def initialize(query_hash, schema)
      @query_hash = query_hash
      @schema = schema
    end

    def call
      coerced = {}
      @schema.properties.each do |k, s|
        original_val = @query_hash[k]
        unless original_val.nil?
          s.type.each do |to_type|
            case to_type
            when "null"
              coerced[k] = nil if original_val.empty?
            when "integer"
              begin
                coerced[k] = Integer(original_val)
              rescue ArgumentError => e
                raise e unless e.message =~ /invalid value for Integer/
              end
            when "number"
              begin
                coerced[k] = Float(original_val)
              rescue ArgumentError => e
                raise e unless e.message =~ /invalid value for Float/
              end
            when "boolean"
              coerced[k] = true if original_val == "true"
              coerced[k] = false if original_val == "false"
            end
            break if coerced.key?(k)
          end
        end
      end
      coerced
    end
  end
end

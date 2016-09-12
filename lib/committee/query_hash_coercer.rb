# Attempts to coerce params given in the query hash (which are all strings) into
# the types specified by the schema.
# Currently supported types: null, integer, number and boolean.
# +call+ returns a hash of all params which could be coerced - coercion errors
# are simply ignored and expected to be handled later by schema validation.
module Committee
  class QueryHashCoercer
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
            begin
              case to_type
              when "null"
                coerced[k] = nil if original_val.empty?
              when "integer"
                coerced[k] = Integer(original_val)
              when "number"
                coerced[k] = Float(original_val)
              when "boolean"
                coerced[k] = true if original_val == "true"
                coerced[k] = false if original_val == "false"
              end
            rescue ArgumentError
            end
            break if coerced.key?(k)
          end
        end
      end
      coerced
    end
  end
end

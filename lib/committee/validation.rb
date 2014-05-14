module Committee
  module Validation
    def check_format(format, value, identifier)
      case format
      when "date-time"
        value =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(\.\d{1,})?(Z|[+-](\d{2})\:(\d{2}))$/
      when "email"
        value =~ /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/i
      when "uuid"
        value =~ /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/
      else
        true
      end
    end

    def check_type(allowed_types, value, identifier)
      types = case value
      when NilClass
        ["null"]
      when TrueClass, FalseClass
        ["boolean"]
      when Bignum, Fixnum
        ["integer", "number"]
      when Float
        ["number"]
      when Hash
        ["object"]
      when String
        ["string"]
      when Array
        ["array"]
      else
        ["unknown"]
      end

      !(allowed_types & types).empty?
    end

    def check_pattern(pattern, value, identifier)
      !pattern || value =~ Regexp.new(pattern)
    end
  end
end

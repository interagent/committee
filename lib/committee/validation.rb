module Committee
  module Validation
    def check_format!(format, value, identifier)
      return if !format
      return if check_format(format, value, identifier)

      description = case identifier
      when String
        %{Invalid format for key "#{identifier}": expected "#{value}" to be "#{format}".}
      when Array
        %{Invalid format at "#{identifier.join(":")}": expected "#{value}" to be "#{format}".}
      end

      raise InvalidFormat, description
    end

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

    def check_type!(allowed_types, value, path)
      types = case value
      when Array
        ["array"]
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
      else
        ["unknown"]
      end
      if (allowed_types & types).empty?
        raise InvalidType,
          %{Invalid type at "#{path.join(":")}": expected #{value} to be #{allowed_types} (was: #{types}).}
      end

    end
  end
end

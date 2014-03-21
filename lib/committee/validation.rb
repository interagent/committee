module Committee
  module Validation
    def check_format!(format, value, path)
      return if !format
      return if check_format(format, value, path)

      raise InvalidResponse,
        %{Invalid format at "#{path.join(":")}": expected "#{value}" to be "#{format}".}
    end

    def check_format(format, value, path)
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
  end
end

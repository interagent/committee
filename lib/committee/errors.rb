module Committee
  class Error < StandardError
  end

  class BadRequest < Error
  end

  class InvalidParams < Error
    def initialize
      @errors = {}
      super("Invalid params")
    end

    def add(id, param, full_message=nil)
      @errors[param.to_sym] = id
    end

    def remove(param)
      @errors.delete(param.to_sym)
    end

    def on(param)
      @errors[param.to_sym]
    end

    def count
      @errors.size
    end

    def full_message
      "Invalid params:\n" + @errors.map do |param, type|
        "  - #{param}: #{error_message(type)}"
      end.join("\n")
    end

    def error_message(type)
      case type
      when :missing
        "is mandatory"
      when :extra
        "unknown parameter"
      when :bad_type
        "has the wrong data type"
      when :bad_format
        "has the wrong format"
      when :bad_pattern
        "doesn't match the specified pattern"
      end
    end
  end

  class InvalidParams < Error
  end

  class InvalidResponse < Error
  end

  class ReferenceNotFound < Error
  end
end

module Committee
  class Schema
    include Enumerable

    def initialize(data)
      @cache = {}
      @schema = MultiJson.decode(data)
      manifest_regex(@schema)
    end

    def [](type)
      @schema["definitions"][type]
    end

    def each
      @schema["definitions"].each do |type, type_schema|
        yield(type, type_schema)
      end
    end

    def find(ref)
      cache(ref) do
        parts = ref.split("/")
        parts.shift if parts.first == "#"
        pointer = @schema
        parts.each do |p|
          next unless pointer
          pointer = pointer[p]
        end
        raise ReferenceNotFound, "Reference not found: #{ref}." if !pointer
        pointer
      end
    end

    private

    def cache(key)
      if @cache[key]
        @cache[key]
      else
        @cache[key] = yield
      end
    end

    def manifest_regex(schema_part)
      schema_part["definitions"].each do |_, type_schema|
        if type_schema.has_key?("definitions")
          manifest_regex(type_schema)
        end
        if pattern = type_schema["pattern"]
          type_schema["pattern"] = Regexp.new(pattern)
        end
      end
    end
  end
end

module Rack::Committee
  class Schema
    include Enumerable

    def initialize(data)
      @schema = MultiJson.decode(data)
    end

    def each
      @schema["definitions"].each do |type, type_schema|
        yield(type, type_schema)
      end
    end

    def find(ref)
      parts = ref.split("/")
      parts.shift if parts.first == ""
      parts.shift if parts.first == "schema"
      parts.each { |p| p.chomp!("#") }
      parts.unshift("definitions")
      pointer = @schema
      parts.each { |p| pointer = pointer[p] }
      pointer
    end
  end
end

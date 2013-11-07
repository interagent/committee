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
  end
end

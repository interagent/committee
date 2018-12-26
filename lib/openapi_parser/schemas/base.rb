module OpenAPIParser::Schemas
  class Base
    include OpenAPIParser::Parser
    include OpenAPIParser::Findable
    include OpenAPIParser::Expandable

    attr_reader :parent, :raw_schema, :object_reference, :root

    # @param [OpenAPIParser::Schemas::Base]
    def initialize(object_reference, parent, root, raw_schema)
      @raw_schema = raw_schema
      @parent = parent
      @root = root
      @object_reference = object_reference

      load_data
      after_init
    end

    # override
    def after_init
    end

    def inspect
      @object_reference
    end
  end
end

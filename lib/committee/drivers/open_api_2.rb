module Committee::Drivers
  class OpenAPI2
    def build_routes(schema)
    end

    def parse(schema)
      schema = JsonSchema.parse!(schema)
      schema.expand_references!
      schema
    end

    # Link abstracts an API link specifically for OpenAPI 2.
    class Link
    end
  end
end

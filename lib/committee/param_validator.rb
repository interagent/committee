module Committee
  class ParamValidator
    include Validation

    def initialize(params, schema, link_schema, options = {})
      @params = params
      @schema = schema
      @link_schema = link_schema
      @allow_extra = options[:allow_extra]
    end

    def call
      @error = InvalidParams.new

      detect_missing
      detect_extra if !@allow_extra
      check_data!

      if @error.count > 0
        raise @error
      end
    end

    private

    def all_keys
      properties = @link_schema["schema"] && @link_schema["schema"]["properties"]
      properties && properties.keys || []
    end

    def check_data!
      return if !@link_schema["schema"] || !@link_schema["schema"]["properties"]

      @link_schema["schema"]["properties"].each do |key, value|
        # don't try to check this unless it was actually specificed
        next unless @params.key?(key)

        if value["type"] != ["array"]
          definitions = find_definitions(value["$ref"])
          try_match(key, @params[key], definitions)
        else
          # only assume one possible array definition for now
          definitions = find_definitions(value["items"]["$ref"])
          array_definition = definitions[0]
          @params[key].each do |item|
            # separate logic for a complex object that includes properties
            if array_definition.key?("properties")
              array_definition["properties"].each do |array_key, array_value|
                return unless item.key?(array_key)

                # @todo: this should really be recursive; only one array level is
                # supported for now
                item_definitions = find_definitions(array_value["$ref"])
                try_match(array_key, item[array_key], item_definitions)
              end
            else
              try_match(key, item, definitions)
            end
          end
        end
      end
    end

    def detect_extra
      (@params.keys - all_keys).each do |param|
        @error.add(:extra, param)
      end
    end

    def detect_missing
      (required_keys - @params.keys).each do |param|
        @error.add(:missing, param)
      end
    end

    def find_definitions(ref)
      definition = @schema.find(ref)
      if definition["anyOf"]
        definition["anyOf"].map { |r| @schema.find(r["$ref"]) }
      else
        [definition]
      end
    end

    def required_keys
      (@link_schema["schema"] && @link_schema["schema"]["required"]) || []
    end

    def try_match(key, value, definitions)
      # try to match data against any possible definition
      definitions.each do |definition|
        if !check_type(definition["type"], value, key)
          @error.add(:bad_type, key)
        elsif !check_format(definition["format"], value, key)
          @error.add(:bad_format, key)
        elsif !check_pattern(definition["pattern"], value, key)
          @error.add(:bad_pattern, key)
        else
          # passed all tests; clear any error from previous definitions
          @error.remove(key)
          break
        end
      end
    end
  end
end

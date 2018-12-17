module OpenAPIParser::Findable
  # @param [String] reference
  # @return [OpenAPIParser::Findable]
  def find_object(reference)
    return nil unless reference.start_with?(object_reference)
    return self if object_reference == reference

    @find_object_cache = {} unless defined? @find_object_cache
    if (obj = @find_object_cache[reference])
      return obj
    end

    if (child = _openapi_all_child_objects[reference])
      @find_object_cache[reference] = child
      return child
    end

    _openapi_all_child_objects.values.each do |c|
      if (obj = c.find_object(reference))
        @find_object_cache[reference] = obj
        return obj
      end
    end

    nil
  end

  def purge_object_cache
    @find_object_cache = {}

    _openapi_all_child_objects.values.each(&:purge_object_cache)
  end
end

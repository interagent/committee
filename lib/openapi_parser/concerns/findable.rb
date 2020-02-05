require 'uri'

module OpenAPIParser::Findable
  # @param [String] reference
  # @return [OpenAPIParser::Findable]
  def find_object(reference)
    return self if object_reference == reference
    remote_reference = !reference.start_with?('#')
    return find_remote_object(reference) if remote_reference
    return nil unless reference.start_with?(object_reference)

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

  private

    def find_remote_object(reference)
      reference_uri = URI(reference)
      fragment = reference_uri.fragment
      reference_uri.fragment = nil
      root.load_another_schema(reference_uri)&.find_object("##{fragment}")
    end
end

module OpenAPIParser::Expandable
  def expand_reference(root)
    expand_list_objects(root, self.class._openapi_attr_list_objects&.keys)
    expand_objects(root, self.class._openapi_attr_objects&.keys)
    expand_hash_objects(root, self.class._openapi_attr_hash_objects&.keys)
    expand_hash_objects(root, self.class._openapi_attr_hash_body_objects&.keys)
  end

  private

  def expand_hash_objects(root, attribute_names)
    return unless attribute_names

    attribute_names.each do |name|
      h = send(name)
      next if h.nil?

      update_values = h.map do |k, v|
        next [k, referenced_object(root, v)] if v.is_a?(OpenAPIParser::Schemas::Reference)
        v.expand_reference(root) if v.is_a?(OpenAPIParser::Expandable)

        nil
      end

      update_values.compact.each do |k, v|
        _update_child_object(h[k], v)
        h[k] = v
      end
    end
  end

  def expand_objects(root, attribute_names)
    return unless attribute_names

    attribute_names.each do |name|
      v = send(name)
      next if v.nil?

      if v.is_a?(OpenAPIParser::Schemas::Reference)
        obj = referenced_object(root, v)
        _update_child_object(v, obj)
        self.instance_variable_set("@#{name}", obj)
      elsif v.is_a?(OpenAPIParser::Expandable)
        v.expand_reference(root)
      end
    end
  end

  def expand_list_objects(root, attribute_names)
    return unless attribute_names

    attribute_names.each do |name|
      l = send(name)
      next if l.nil?

      l.each_with_index do |v, idx|
        if v.is_a?(OpenAPIParser::Schemas::Reference)
          obj = referenced_object(root, v)
          _update_child_object(v, obj)
          l[idx] = obj
        elsif v.is_a?(OpenAPIParser::Expandable)
          v.expand_reference(root)
        end
      end
    end
  end


  # @param [OpenAPIParser::Schemas::OpenAPI] root
  # @param [OpenAPIParser::Schemas::Reference] reference
  def referenced_object(root, reference)
    obj = root.find_object(reference.ref)

    obj.is_a?(OpenAPIParser::Schemas::Reference) ? referenced_object(root, obj) : obj
  end
end

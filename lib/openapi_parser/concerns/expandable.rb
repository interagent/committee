module OpenAPIParser::Expandable
  # expand refs
  # @param [OpenAPIParser::Schemas::Base] root
  # @return nil
  def expand_reference(root)
    expand_list_objects(root, self.class._openapi_attr_list_objects.keys)
    expand_objects(root, self.class._openapi_attr_objects.keys)
    expand_hash_objects(root, self.class._openapi_attr_hash_objects.keys)
    expand_hash_objects(root, self.class._openapi_attr_hash_body_objects.keys)
    nil
  end

  private

    def expand_hash_objects(root, attribute_names)
      return unless attribute_names

      attribute_names.each { |name| expand_hash_attribute(root, name) }
    end

    def expand_hash_attribute(root, name)
      h = send(name)
      return if h.nil?

      update_values = h.map do |k, v|
        new_object = expand_object(root, v)
        new_object.nil? ? nil : [k, new_object]
      end

      update_values.compact.each do |k, v|
        _update_child_object(h[k], v)
        h[k] = v
      end
    end

    def expand_objects(root, attribute_names)
      return unless attribute_names

      attribute_names.each do |name|
        v = send(name)
        next if v.nil?

        new_object = expand_object(root, v)
        next if new_object.nil?

        _update_child_object(v, new_object)
        self.instance_variable_set("@#{name}", new_object)
      end
    end

    def expand_list_objects(root, attribute_names)
      return unless attribute_names

      attribute_names.each do |name|
        l = send(name)
        next if l.nil?

        l.each_with_index do |v, idx|
          new_object = expand_object(root, v)
          next if new_object.nil?

          _update_child_object(v, new_object)
          l[idx] = new_object
        end
      end
    end

    def expand_object(root, object)
      if object.kind_of?(OpenAPIParser::Schemas::Reference)
        return referenced_object(root, object)
      end

      object.expand_reference(root) if object.kind_of?(OpenAPIParser::Expandable)
      nil
    end

    # @param [OpenAPIParser::Schemas::OpenAPI] root
    # @param [OpenAPIParser::Schemas::Reference] reference
    def referenced_object(root, reference)
      obj = root.find_object(reference.ref)

      obj.kind_of?(OpenAPIParser::Schemas::Reference) ? referenced_object(root, obj) : obj
    end
end

# frozen_string_literal: true

module Committee
  class SchemaLocations
    def initialize(path, data)
      @path = path
      @data = data
      @lines = {}
      @data_lines = {}
      @external_locations = {}
      document = YAML.parse_file(path)
      anchors = {}
      document.each do |node|
        anchors[node.anchor] = node if node.respond_to?(:anchor) && node.anchor && !node.is_a?(Psych::Nodes::Alias)
      end
      record(document.root, data, '#', anchors)
    end

    def message(message, data, reference = nil)
      line = @data_lines[data.object_id] || @lines[reference]
      line ? "#{message} (#{@path}:#{line})" : message
    end

    def open_api_3_message(message, response, reference)
      schema = find_schema(response, reference, {})
      return message unless schema
      return self.message(message, schema.raw_schema, reference) if schema.root.raw_schema.equal?(@data)

      # openapi_parser has no public reader for a document's source URI.
      uri = schema.root.instance_variable_get(:@uri)
      return message unless uri&.scheme == 'file' && ['.yml', '.yaml'].include?(File.extname(uri.path))

      locations = @external_locations[schema.root] ||= self.class.new(uri.path, schema.root.raw_schema)
      locations.message(message, schema.raw_schema, reference)
    rescue SystemCallError, Psych::Exception
      message
    end

    private

    def record(node, data, reference, anchors)
      node = anchors[node.anchor] if node.is_a?(Psych::Nodes::Alias)
      return unless node

      @lines[reference] = node.start_line + 1
      return unless data.is_a?(Hash) || data.is_a?(Array)
      return if @data_lines.key?(data.object_id)

      @data_lines[data.object_id] = node.start_line + 1
      case node
      when Psych::Nodes::Mapping
        values = data.transform_keys(&:to_s)
        mapping_nodes(node, anchors).each do |key, value|
          escaped_key = key.gsub('~', '~0').gsub('/', '~1')
          record(value, values[key], "#{reference}/#{escaped_key}", anchors)
        end
      when Psych::Nodes::Sequence
        node.children.each_with_index { |child, index| record(child, data[index], "#{reference}/#{index}", anchors) }
      end
    end

    def mapping_nodes(node, anchors, visited = {})
      node = anchors[node.anchor] if node.is_a?(Psych::Nodes::Alias)
      return {} unless node && !visited[node.object_id]

      visited = visited.merge(node.object_id => true)
      if node.is_a?(Psych::Nodes::Sequence)
        return node.children.reverse_each.each_with_object({}) { |child, result| result.merge!(mapping_nodes(child, anchors, visited)) }
      end
      return {} unless node.is_a?(Psych::Nodes::Mapping)

      merged = {}
      explicit = {}
      node.children.each_slice(2) do |key, value|
        if key.value == '<<'
          merged.merge!(mapping_nodes(value, anchors, visited))
        else
          explicit[key.value] = value
        end
      end
      merged.merge(explicit)
    end

    def find_schema(schema, reference, visited)
      return unless schema && !visited[schema.object_id]
      return schema if schema.object_reference == reference

      visited[schema.object_id] = true
      schema._openapi_all_child_objects.each_value do |child|
        found = find_schema(child, reference, visited)
        return found if found
      end
      nil
    end
  end
end

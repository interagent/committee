#TODO: move better namespace
module Committee
  class SchemaValidator::OpenAPI3::TemplatedPaths
    def initialize(definitions)
      @definitions = definitions

      @root = PathNode.new
      @definitions.raw['paths'].each { |path, _path_item_object| @root.register_path_node(path.split("/"), path) }
    end

    def operation_object(request_path, method)
      original_path = @root.find_full_path(request_path.split("/"))
      return nil unless original_path

      path_item_object = @definitions.path_by_path(original_path)
      path_item_object.raw[method] ? path_item_object.endpoint_by_method(method) : nil
    end

    class PathNode
      attr_accessor :full_path

      def initialize
        @children = Hash.new {|h, k| h[k] = PathNode.new }
        @path_template_node = nil # we can't initialize because recursive initialize...
        @full_path = nil
      end

      def register_path_node(splited_path, full_path)
        if splited_path.empty?
          @full_path = full_path
          return
        end

        path_name = splited_path.shift

        child = path_template?(path_name) ? path_template_node : children[path_name]
        child.register_path_node(splited_path, full_path)
      end

      # @return <String, nil>
      def find_full_path(splited_path)
        return @full_path if splited_path.empty?

        path_name = splited_path.shift

        # when ambiguous matching like this
        # /{entity}/me
        # /books/{id}
        # OpenAPI3 depend on the tooling so we use concrete one (using /books/)
        child = children.key?(path_name) ? children[path_name] : path_template_node
        child.find_full_path(splited_path)
      end

      private

      attr_reader :children

      def path_template_node
        @path_template_node ||= PathNode.new
      end

      def path_template?(path_name)
        path_name.start_with?('{') && path_name.end_with?('}')
      end
    end
  end
end

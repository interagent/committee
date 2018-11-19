#TODO: move better namespace
module Committee
  class SchemaValidator::OpenAPI3::TemplatedPaths
    def initialize(definitions)
      @definitions = definitions

      @root = PathNode.new('/')
      @definitions.raw['paths'].each { |path, _path_item_object| @root.register_path_node(path.split("/"), path) }
    end

    def operation_object(request_path, method)
      original_path, path_params = @root.find_full_path(request_path.split("/"))
      return nil, path_params unless original_path

      path_item_object = @definitions.path_by_path(original_path)
      obj = path_item_object.raw[method] ? path_item_object.endpoint_by_method(method) : nil

      [obj, path_params]
    end

    class PathNode
      attr_accessor :full_path, :name

      def initialize(name)
        @name = name
        @children = Hash.new {|h, k| h[k] = PathNode.new(k) }
        @path_template_node = nil # we can't initialize because recursive initialize...
        @full_path = nil
      end

      def register_path_node(splited_path, full_path)
        if splited_path.empty?
          @full_path = full_path
          return
        end

        path_name = splited_path.shift

        child = path_template?(path_name) ? path_template_node(path_name) : children[path_name]
        child.register_path_node(splited_path, full_path)
      end

      # TODO: good comment
      # @return <String, nil> and Hash
      def find_full_path(splited_path)
        return [@full_path, {}] if splited_path.empty?

        path_name = splited_path.shift

        # when ambiguous matching like this
        # /{entity}/me
        # /books/{id}
        # OpenAPI3 depend on the tooling so we use concrete one (using /books/)

        path_params = {}
        if children.key?(path_name)
          child = children[path_name]
        else
          child = path_template_node(path_name)
          path_params = {"#{child.name}" =>path_name}
        end

        ret, other_path_params = child.find_full_path(splited_path)
        [ret, path_params.merge(other_path_params)]
      end

      private

      attr_reader :children

      def path_template_node(path_name)
        @path_template_node ||= PathNode.new(path_name[1..(path_name.length-2)]) # delete {} from {name}
      end

      def path_template?(path_name)
        path_name.start_with?('{') && path_name.end_with?('}')
      end
    end
  end
end

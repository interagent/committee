# frozen_string_literal: true

module Committee
  module Test
    # Handles temporary parameter exclusion during schema validation
    # Allows testing error responses without validation failures for intentionally missing parameters
    class ExceptParameter
      # @param [Rack::Request] request The request object
      # @param [Hash] committee_options Committee options hash
      def initialize(request, committee_options)
        @request = request
        @committee_options = committee_options
        @original_values = {}
      end

      # Apply dummy values to excepted parameters
      # @param [Hash] except Hash of parameter types to parameter names
      #   (e.g., { headers: ['content-type'], query: ['page'] })
      # @return [void]
      def apply(except)
        except.each do |param_type, param_names|
          handler = handler_for(param_type)
          handler&.apply(param_names, @original_values)
        end
      end

      # Restore original parameter values
      # @return [void]
      def restore
        @original_values.each do |storage_key, value|
          if storage_key.include?(':')
            restore_namespaced_param(storage_key, value)
          else
            restore_env_param(storage_key, value)
          end
        end
      end

      private

      def handler_for(param_type)
        case param_type
        when :headers then HeaderHandler.new(@request)
        when :query then QueryHandler.new(@request)
        when :path then PathHandler.new(@request)
        when :body then BodyHandler.new(@request, @committee_options)
        end
      end

      def restore_namespaced_param(storage_key, value)
        prefix, param_name = storage_key.split(':', 2)
        storage = storage_for_prefix(prefix)
        set_or_delete(storage, param_name, value) if storage
      end

      def restore_env_param(storage_key, value)
        set_or_delete(@request.env, storage_key, value)
      end

      def storage_for_prefix(prefix)
        case prefix
        when 'query' then @request.env['rack.request.query_hash']
        when 'path' then @request.env['router.params']
        when 'body' then @request.env[@committee_options.fetch(:request_body_hash_key, 'committee.request_body_hash')]
        end
      end

      def set_or_delete(hash, key, value)
        value.nil? ? hash.delete(key) : hash[key] = value
      end

      # Base handler for parameters stored in hash-like structures
      # Provides common logic for applying dummy values to parameters
      class BaseHashParameterHandler
        # @param [Rack::Request] request The request object
        def initialize(request)
          @request = request
        end

        # Apply dummy values to parameters
        # @param [Array<String, Symbol>] param_names Parameter names to except
        # @param [Hash] original_values Hash to store original values for restoration
        # @return [void]
        def apply(param_names, original_values)
          storage = get_storage
          return unless should_process?(storage)

          param_names.each do |param_name|
            key = param_name.to_s
            original_values["#{prefix}:#{key}"] = storage[key]
            storage[key] ||= "dummy-#{param_name}"
          end
        end

        private

        # Override in subclasses to specify the storage location
        def get_storage
          raise NotImplementedError, "#{self.class} must implement #get_storage"
        end

        # Override in subclasses to specify the prefix for original_values keys
        def prefix
          raise NotImplementedError, "#{self.class} must implement #prefix"
        end

        # Override in subclasses if custom validation is needed
        def should_process?(storage)
          !storage.nil?
        end
      end

      # Handler for request headers
      class HeaderHandler
        # @param [Rack::Request] request The request object
        def initialize(request)
          @request = request
        end

        # Apply dummy values to header parameters
        # @param [Array<String, Symbol>] param_names Header names to except
        # @param [Hash] original_values Hash to store original values for restoration
        # @return [void]
        def apply(param_names, original_values)
          param_names.each do |param_name|
            key = "HTTP_#{param_name.to_s.upcase.tr('-', '_')}"
            original_values[key] = @request.env[key]
            @request.env[key] ||= "dummy-#{param_name}"
          end
        end
      end

      # Handler for query parameters
      class QueryHandler < BaseHashParameterHandler
        private

        def get_storage
          # Initialize rack.request.query_hash if not yet initialized
          @request.env['rack.request.query_hash'] ||= {}
        end

        def prefix
          'query'
        end
      end

      # Handler for path parameters
      class PathHandler < BaseHashParameterHandler
        private

        def get_storage
          @request.env['router.params']
        end

        def prefix
          'path'
        end
      end

      # Handler for body parameters
      class BodyHandler < BaseHashParameterHandler
        # @param [Rack::Request] request The request object
        # @param [Hash] committee_options Committee options hash
        def initialize(request, committee_options)
          super(request)
          @committee_options = committee_options
        end

        private

        def get_storage
          body_key = @committee_options.fetch(:request_body_hash_key, 'committee.request_body_hash')
          @request.env[body_key]
        end

        def prefix
          'body'
        end

        def should_process?(storage)
          storage.is_a?(Hash)
        end
      end
    end
  end
end

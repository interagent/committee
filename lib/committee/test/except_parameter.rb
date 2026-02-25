# frozen_string_literal: true

module Committee
  module Test
    # Handles temporary parameter exclusion during schema validation.
    # Allows testing error responses without validation failures for intentionally missing parameters.
    class ExceptParameter
      FORMAT_DUMMIES = { 'date-time': '2000-01-01T00:00:00Z', date: '2000-01-01', email: 'dummy@example.com', uuid: '00000000-0000-0000-0000-000000000000' }.freeze

      # @param [Rack::Request] request The request object
      # @param [Hash] committee_options Committee options hash
      def initialize(request, committee_options)
        @request = request
        @committee_options = committee_options
        @handlers = {}
      end

      # Apply dummy values to excepted parameters
      # @param [Hash] except Hash of parameter types to parameter names
      #   (e.g., { headers: ['authorization'], query: ['page'] })
      # @return [void]
      def apply(except)
        except.each do |param_type, param_names|
          handler = (@handlers[param_type] ||= handler_for(param_type))
          handler&.apply(param_names)
        end
      end

      # Restore original parameter values
      # @return [void]
      def restore
        @handlers.each_value(&:restore)
      end

      private

      def handler_for(param_type)
        case param_type
        when :headers then HeaderHandler.new(@request, @committee_options)
        when :query   then QueryHandler.new(@request, @committee_options)
        when :body    then BodyHandler.new(@request, @committee_options)
        end
      end

      # Shared helpers for looking up OpenAPI3 parameter schemas and generating
      # type/format/enum-aware dummy values encoded as HTTP strings.
      #
      # Included by BaseHashParameterHandler, HeaderHandler, and BodyHandler.
      module StringDummyLookup
        private

        # Resolve the OpenAPI3 operation object for the current request.
        # Returns nil for non-OpenAPI3 schemas or any lookup failure.
        def resolve_operation
          schema = @committee_options[:schema]
          return nil unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

          path = @request.path_info
          if (prefix = @committee_options[:prefix])
            path = path.gsub(Regexp.new("\\A#{Regexp.escape(prefix)}"), '')
          end

          schema.operation_object(path, @request.request_method.downcase)
        end

        # Find the OpenAPI3 schema object for a parameter by name and location.
        # Returns nil for non-OpenAPI3 schemas or any lookup failure.
        def find_parameter_schema(key, location)
          operation = resolve_operation
          return nil unless operation

          params = operation.request_operation.operation_object&.parameters
          params&.find { |p| p.name&.casecmp?(key.to_s) && p.in == location }&.schema
        rescue StandardError
          nil
        end

        # Return a type-appropriate dummy value encoded as a String (or Array of strings
        # for array-typed query/path params). The value must be coerceable to the
        # expected schema type by openapi_parser's coerce_value option.
        def string_dummy_for_schema(key, param_schema)
          return "dummy-#{key}" unless param_schema
          return param_schema.enum.first.to_s if param_schema.enum&.any?

          case param_schema.type
          when 'integer', 'number' then '0'
          when 'boolean'           then 'true'
          when 'array'             then ['0']
          when 'string'            then string_format_dummy(key, param_schema.format)
          else "dummy-#{key}"
          end
        end

        # Return a string that satisfies common OpenAPI3 string format constraints.
        def string_format_dummy(key, format)
          FORMAT_DUMMIES.fetch(format&.to_sym, "dummy-#{key}")
        end
      end

      # Base handler for parameters stored in hash-like structures.
      # Subclasses implement #get_storage and optionally #dummy_value_for.
      class BaseHashParameterHandler
        include StringDummyLookup

        # @param [Rack::Request] request The request object
        # @param [Hash] committee_options Committee options hash
        def initialize(request, committee_options)
          @request = request
          @committee_options = committee_options
          @original_values = {}
        end

        # Apply dummy values to parameters
        # @param [Array<String, Symbol>] param_names Parameter names to except
        # @return [void]
        def apply(param_names)
          storage = get_storage
          return unless storage

          param_names.each do |param_name|
            key = param_name.to_s
            @original_values[key] = storage[key]
            storage[key] ||= dummy_value_for(key)
          end
        end

        # Restore original parameter values
        # @return [void]
        def restore
          storage = get_storage
          return unless storage

          @original_values.each do |key, value|
            value.nil? ? storage.delete(key) : storage[key] = value
          end
        end

        private

        # Override in subclasses to specify the storage location
        # @return [Hash, nil]
        def get_storage
          raise NotImplementedError, "#{self.class} must implement #get_storage"
        end

        def dummy_value_for(key)
          "dummy-#{key}"
        end
      end

      # Handler for request headers
      class HeaderHandler
        include StringDummyLookup

        # In Rack/CGI, Content-Type and Content-Length are stored without the
        # HTTP_ prefix. All other headers use the HTTP_ prefix convention.
        SPECIAL_RACK_HEADERS = { 'content-type' => 'CONTENT_TYPE', 'content-length' => 'CONTENT_LENGTH', }.freeze
        private_constant :SPECIAL_RACK_HEADERS

        # @param [Rack::Request] request The request object
        # @param [Hash] committee_options Committee options hash
        def initialize(request, committee_options)
          @request = request
          @committee_options = committee_options
          @original_values = {}
        end

        # Apply dummy values to header parameters
        # @param [Array<String, Symbol>] param_names Header names to except
        # @return [void]
        def apply(param_names)
          param_names.each do |param_name|
            key = rack_header_key(param_name.to_s)
            @original_values[key] = @request.env[key]
            @request.env[key] ||= string_dummy_for_schema(param_name.to_s, find_parameter_schema(param_name.to_s, 'header'))
          end
        end

        # Restore original header values
        # @return [void]
        def restore
          @original_values.each do |key, value|
            value.nil? ? @request.env.delete(key) : @request.env[key] = value
          end
        end

        private

        def rack_header_key(name)
          SPECIAL_RACK_HEADERS[name.downcase] || "HTTP_#{name.upcase.tr('-', '_')}"
        end
      end

      # Handler for query parameters
      class QueryHandler < BaseHashParameterHandler
        private

        def get_storage
          # Calling request.GET ensures Rack parses the query string into
          # rack.request.query_hash before we inject dummy values, so that
          # any existing query parameters are preserved.
          @request.GET
        end

        def dummy_value_for(key)
          string_dummy_for_schema(key, find_parameter_schema(key, 'query'))
        end
      end

      # Handler for request body parameters
      #
      # Supports three content types:
      # - application/json (and variants): replaces rack.input stream so that
      #   request_unpack re-parses the modified body during validation.
      # - application/x-www-form-urlencoded / multipart/form-data: pre-populates
      #   rack.request.form_hash, which Rack returns directly from request.POST
      #   without re-parsing the raw body.
      # - Other content types (e.g. binary): no-op, as RequestUnpacker does not
      #   extract named parameters from them.
      class BodyHandler
        include StringDummyLookup

        # @param [Rack::Request] request The request object
        # @param [Hash] committee_options Committee options hash
        def initialize(request, committee_options)
          @request = request
          @committee_options = committee_options
          @original_body        = nil
          @original_form_values = nil
        end

        # Apply dummy values to body parameters based on content type.
        # @param [Array<String, Symbol>] param_names Body parameter names to except
        # @return [void]
        def apply(param_names)
          if json_content_type?
            apply_json(param_names)
          elsif form_content_type?
            apply_form(param_names)
          end
          # Other content types: no-op
        end

        # Restore original body content
        # @return [void]
        def restore
          restore_json if @original_body
          restore_form if @original_form_values
        end

        private

        def json_content_type?
          mt = @request.media_type
          mt.nil? || mt.match?(%r{application/(?:.*\+)?json})
        end

        def form_content_type?
          mt = @request.media_type
          mt == 'application/x-www-form-urlencoded' || mt&.start_with?('multipart/form-data')
        end

        # --- JSON body handling ---
        #
        # Replaces rack.input with a modified JSON body. Also clears any stale
        # rack.request.form_hash / rack.request.form_pairs caches so that Rack
        # does not return outdated form data if POST is called after the swap.

        def apply_json(param_names)
          original_body = read_body
          body_hash = parse_body(original_body)

          # Commit state only after successful parse so that restore_json is not
          # triggered unnecessarily when parse_body raises (e.g. invalid JSON).
          @original_body    = original_body
          @saved_form_hash  = @request.env.delete('rack.request.form_hash')
          @saved_form_pairs = @request.env.delete('rack.request.form_pairs')

          param_names.each do |param_name|
            key = param_name.to_s
            body_hash[key] = dummy_value_for(key) if body_hash[key].nil?
          end

          replace_body(JSON.generate(body_hash))
        end

        def restore_json
          replace_body(@original_body)
          @request.env.delete(body_hash_key)
          @request.env['rack.request.form_hash']  = @saved_form_hash  if @saved_form_hash
          @request.env['rack.request.form_pairs'] = @saved_form_pairs if @saved_form_pairs
        end

        # --- Form body handling ---
        #
        # Calls request.POST to trigger Rack's form parsing (populating
        # rack.request.form_hash from rack.input), then injects dummy values
        # for missing params into the live hash. In Rack 3.x, request.POST
        # returns rack.request.form_hash directly on subsequent calls, so the
        # injected values are visible during validation.

        def apply_form(param_names)
          @request.body&.rewind
          form_hash = @request.POST
          @original_form_values = {}
          param_names.each do |param_name|
            key = param_name.to_s
            @original_form_values[key] = form_hash[key]
            form_hash[key] ||= form_dummy_for(key)
          end
        rescue StandardError
          # If form parsing fails (e.g. malformed body), skip remaining injection.
          # Use ||= so that any originals already saved in the loop are preserved
          # and can be correctly restored by restore_form.
          @original_form_values ||= {}
        end

        def restore_form
          form_hash = @request.env['rack.request.form_hash']
          return unless form_hash

          @original_form_values.each do |key, value|
            value.nil? ? form_hash.delete(key) : form_hash[key] = value
          end
        end

        # --- Dummy value helpers ---

        def body_hash_key
          @committee_options.fetch(:request_body_hash_key, 'committee.request_body_hash')
        end

        def read_body
          return '' unless @request.body

          @request.body.rewind
          body = @request.body.read
          @request.body.rewind
          body || ''
        end

        def parse_body(body_str)
          return {} if body_str.nil? || body_str.empty?

          JSON.parse(body_str)
        end

        def replace_body(body_str)
          @request.env['rack.input'] = StringIO.new(body_str)
        end

        # Returns a native-typed dummy value for JSON bodies.
        def dummy_value_for(key)
          prop_schema = body_param_schema(key)
          return "dummy-#{key}" unless prop_schema

          return prop_schema.enum.first if prop_schema.enum&.any?

          case prop_schema.type
          when 'integer' then 0
          when 'number'  then 0.0
          when 'boolean' then false
          when 'array'   then []
          when 'object'  then {}
          when 'string'  then FORMAT_DUMMIES.fetch(prop_schema.format&.to_sym, "dummy-#{key}")
          else "dummy-#{key}"
          end
        end

        # Returns a string-encoded dummy value for form bodies.
        # Form data is always transmitted as strings; openapi_parser's coerce_value
        # handles conversion to the declared type during validation.
        def form_dummy_for(key)
          prop_schema = body_param_schema(key)
          return "dummy-#{key}" unless prop_schema

          return prop_schema.enum.first.to_s if prop_schema.enum&.any?

          case prop_schema.type
          when 'integer', 'number' then '0'
          when 'boolean'           then 'true'
          when 'array'             then ['0']
          when 'string'            then FORMAT_DUMMIES.fetch(prop_schema.format&.to_sym, "dummy-#{key}").to_s
          else "dummy-#{key}"
          end
        end

        def body_param_schema(key)
          operation = resolve_operation
          return nil unless operation

          request_body = operation.request_operation.operation_object&.request_body
          return nil unless request_body

          request_body.content&.each_value do |media_type|
            next unless media_type.schema&.properties

            prop = media_type.schema.properties[key]
            return prop if prop
          end

          nil
        rescue StandardError
          nil
        end
      end
    end
  end
end

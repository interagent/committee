# TODO: Support OpenAPI3
module Committee::Test
  module Methods
    def assert_schema_conform
      @committee_schema ||= begin
        # The preferred option. The user has already parsed a schema elsewhere
        # and we therefore don't have to worry about any performance
        # implications of having to do it for every single test suite.
        if committee_schema
          committee_schema
        else
          schema = schema_contents

          if schema.is_a?(String)
            warn_string_deprecated
          elsif schema.is_a?(Hash)
            warn_hash_deprecated
          end

          if schema.is_a?(String)
            schema = JSON.parse(schema)
          end

          if schema.is_a?(Hash) || schema.is_a?(JsonSchema::Schema)
            driver = Committee::Drivers::HyperSchema.new

            # The driver itself has its own special cases to be able to parse
            # either a hash or JsonSchema::Schema object.
            schema = driver.parse(schema)
          end

          schema
        end
      end

      validator_option = Committee::SchemaValidator::Option.new({prefix: schema_url_prefix}, @committee_schema, :hyper_schema)
      @committee_router ||= Committee::SchemaValidator::HyperSchema::Router.new(@committee_schema, validator_option)

      link, _ = @committee_router.find_request_link(last_request)
      unless link
        response = "`#{last_request.request_method} #{last_request.path_info}` undefined in schema."
        raise Committee::InvalidResponse.new(response)
      end

      if validate_response?(last_response.status)
        data = JSON.parse(last_response.body)
        Committee::SchemaValidator::HyperSchema::ResponseValidator.new(link).call(last_response.status, last_response.headers, data)
      end
    end

    def assert_schema_content_type
      Committee.warn_deprecated("Committee: use of #assert_schema_content_type is deprecated; use #assert_schema_conform instead.")
    end

    # Can be overridden with a different driver name for other API definition
    # formats.
    def committee_schema
      nil
    end

    # can be overridden alternatively to #schema_path in case the schema is
    # easier to access as a string
    # blob
    def schema_contents
      JSON.parse(File.read(schema_path))
    end

    def schema_path
      raise "Please override #committee_schema."
    end

    def schema_url_prefix
      nil
    end

    def warn_hash_deprecated
      Committee.warn_deprecated("Committee: returning a hash from " \
        "#schema_contents and using #schema_path is deprecated; please " \
        "override #committee_schema instead.")
    end

    def warn_string_deprecated
      Committee.warn_deprecated("Committee: returning a string from " \
        "#schema_contents is deprecated; please override #committee_schema " \
        "instead.")
    end

    def validate_response?(status)
      Committee::SchemaValidator::HyperSchema::ResponseValidator.validate?(status)
    end
  end
end

# frozen_string_literal: true

module Committee
  module SchemaValidator
    class OpenAPI3
      class RequestValidator
        # @param [SchemaValidator::OpenAPI3::OperationWrapper] operation_object
        # @param [Committee::SchemaValidator::Option] validator_option
        def initialize(operation_object, validator_option:)
          @operation_object = operation_object
          @validator_option = validator_option
        end

        def call(request, path_params, query_params, body_params, headers)
          content_type = ::Committee::SchemaValidator.request_media_type(request)
          check_content_type(request, content_type) if @validator_option.check_content_type

          @operation_object.validate_request_params(path_params, query_params, body_params, headers, @validator_option)
        end

        private

        def check_content_type(request, content_type)
          # support post, put, patch only
          return true unless request.post? || request.put? || request.patch?
          return true if @operation_object.valid_request_content_type?(content_type)

          message = if valid_content_types.size > 1
                      types = valid_content_types.map {|x| %{"#{x}"} }.join(', ')
                      %{"Content-Type" request header must be set to any of the following: [#{types}].}
                    else
                      %{"Content-Type" request header must be set to "#{valid_content_types.first}".}
                    end
          raise Committee::InvalidRequest, message
        end

        def valid_content_types
          @operation_object&.request_content_types
        end
      end
    end
  end
end

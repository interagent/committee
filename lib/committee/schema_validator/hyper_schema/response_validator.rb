# frozen_string_literal: true

module Committee
  module SchemaValidator
    class HyperSchema
      class ResponseValidator
        attr_reader :validate_success_only

        def initialize(link, options = {})
          @link = link
          @validate_success_only = options[:validate_success_only]

          @validator = JsonSchema::Validator.new(target_schema(link))
        end

        def call(status, headers, data)
          unless [204, 304].include?(status) # 204 No Content or 304 Not Modified
            response = Rack::Response.new(data, status, headers)
            check_content_type!(response)
          end

          # List is a special case; expect data in an array.
          #
          # This is poor form that's here so as not to introduce breaking behavior.
          # The "instances" value of "rel" is a Heroku-ism and was originally
          # introduced before we understood how to use "targetSchema". It's not
          # meaningful with the context of the hyper-schema specification and
          # should be eventually be removed.
          if legacy_hyper_schema_rel?(@link)
            if !data.is_a?(Array)
              raise InvalidResponse, "List endpoints must return an array of objects."
            end

            # only consider the first object during the validation from here on
            # (but only in cases where `targetSchema` is not set)
            data = data[0]

            # if the array was empty, allow it through
            return if data == nil
          end

          if Committee::Middleware::ResponseValidation.validate?(status, validate_success_only) && !@validator.validate(data)
            errors = JsonSchema::SchemaError.aggregate(@validator.errors).join("\n")
            raise InvalidResponse, "Invalid response.\n\n#{errors}"
          end
        end

        private

        def response_media_type(response)
          if response.respond_to?(:media_type)
            response.media_type.to_s
          else
            # for rack compatibility. In rack v 1.5.0, Rack::Response doesn't have media_type
            response.content_type.to_s.split(";").first.to_s
          end
        end


        def check_content_type!(response)
          if @link.media_type
            unless Rack::Mime.match?(response_media_type(response), @link.media_type)
              raise Committee::InvalidResponse,
                %{"Content-Type" response header must be set to "#{@link.media_type}".}
            end
          end
        end

        def legacy_hyper_schema_rel?(link)
          link.is_a?(Committee::Drivers::HyperSchema::Link) &&
            link.rel == "instances" &&
            !link.target_schema
        end

        # Gets the target schema of a link. This is normally just the standard
        # response schema, but we allow some legacy behavior for hyper-schema links
        # tagged with rel=instances to instead use the schema of their parent
        # resource.
        def target_schema(link)
          if link.target_schema
            link.target_schema
          elsif legacy_hyper_schema_rel?(link)
            link.parent
          end
        end
      end
    end
  end
end

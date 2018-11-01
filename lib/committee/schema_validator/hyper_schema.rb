class Committee::SchemaValidator
  class HyperSchema
    attr_reader :link, :param_matches

    def initialize(router, request)
      @link, @param_matches = router.find_request_link(request)
    end

    def coerce_path_params
      return unless link_exist?
      param_matches.merge(
          Committee::StringParamsCoercer.new(
              param_matches,
              link.schema
          ).call
      )
    end

    def coerce_query_params(request)
      return unless link_exist?
      return if request.GET.nil? || link.schema.nil?

      request.env["rack.request.query_hash"].merge!(
          Committee::StringParamsCoercer.new(
              request.GET,
              link.schema
          ).call
      )
    end

    def validate_request(request, params_key, check_content_type)
      return unless link_exist?

      validator = Committee::RequestValidator.new(link, check_content_type: check_content_type)
      validator.call(request, request.env[params_key])
    end

    def link_exist?
      !link.nil?
    end
  end
end

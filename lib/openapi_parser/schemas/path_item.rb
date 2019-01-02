# TODO: support servers
# TODO: support reference

module OpenAPIParser::Schemas
  class PathItem < Base
    include OpenAPIParser::ParameterValidatable

    openapi_attr_values :summary, :description

    openapi_attr_objects :get, :put, :post, :delete, :options, :head, :patch, :trace, Operation
    openapi_attr_list_object :parameters, Parameter, reference: true

    # @return [Operation]
    def operation(method)
      send(method)
    end
  end
end

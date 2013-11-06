require "multi_json"
require "rack"

require_relative "committee/errors"
require_relative "committee/param_validator"
require_relative "committee/request_unpacker"
require_relative "committee/routes_builder"

module Rack
  class Committee
    def initialize(app, options={})
      @app = app

      blobs = options[:schema] || raise("need option `schema`")
      blobs = [blobs] if !blobs.is_a?(Array)
      @params_key = options[:params_key] || "committee.params"

      @schemata = {}
      blobs.map { |b| MultiJson.decode(b) }.each do |schema|
        @schemata[schema["id"]] = schema
      end
      @routes = RoutesBuilder.new(@schemata).call
    end

    def call(env)
      env[@params_key] = RequestUnpacker.new(env).call
      if method_routes = @routes[env["REQUEST_METHOD"]]
        method_routes.each do |pattern, link|
          if env["PATH_INFO"] =~ pattern
            ParamValidator.new(env[@params_key], link).call
          end
        end
      end
      @app.call(env)
    rescue BadRequest
      [400, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: :bad_request, error: $!.message)]]
    end
  end
end

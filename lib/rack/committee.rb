require "multi_json"
require "rack"

require_relative "committee/errors"
require_relative "committee/param_validator"
require_relative "committee/request_unpacker"
require_relative "committee/router"

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
      @router = Router.new(@schemata)
    end

    def call(env)
      env[@params_key] = RequestUnpacker.new(env).call
      if link = @router.routes?(env["REQUEST_METHOD"], env["PATH_INFO"])
        ParamValidator.new(env[@params_key], link).call
      end
      @app.call(env)
    rescue BadRequest
      render_error(400, :bad_request, $!.message)
    rescue InvalidParams
      render_error(422, :invalid_params, $!.message)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: id, error: message)]]
    end
  end
end

module Committee
  class Base
    def initialize(app, options={})
      @app = app

      @params_key = options[:params_key] || "committee.params"
      data = options[:schema] || raise("need option `schema`")
      @schema = Schema.new(data)
      @router = Router.new(@schema)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json; charset=utf-8" },
        [MultiJson.encode(id: id, error: message)]]
    end
  end
end

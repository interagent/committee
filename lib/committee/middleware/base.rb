module Committee::Middleware
  class Base
    def initialize(app, options={})
      @app = app

      @params_key = options[:params_key] || "committee.params"
      data = options[:schema] || raise("need option `schema`")
      @schema = Committee::Schema.new(data)
      @router = Committee::Router.new(@schema)
    end

    private

    def render_error(status, id, message)
      [status, { "Content-Type" => "application/json" },
        [MultiJson.encode({ id: id, error: message }, pretty: true)]]
    end
  end
end

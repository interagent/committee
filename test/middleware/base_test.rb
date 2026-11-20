# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Base do
  include Rack::Test::Methods

  def app
    @app
  end

  it "accepts just a schema object" do
    @app = new_rack_app(schema: hyper_schema)
    params = { "name" => "cloudnasium" }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts just a OpenAPI3 schema object" do
    @app = new_rack_app(schema: open_api_3_schema)
    params = { "name" => "cloudnasium" }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "doesn't accept a schema string" do
    @app = new_rack_app(schema: JSON.dump(hyper_schema_data))
    params = { "name" => "cloudnasium" }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " + "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept a schema hash" do
    @app = new_rack_app(schema: hyper_schema_data)
    params = { "name" => "cloudnasium" }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " + "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept a JsonSchema::Schema object" do
    @app = new_rack_app(schema: JsonSchema.parse!(hyper_schema_data))
    params = { "name" => "cloudnasium" }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " + "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept other schema types" do
    @app = new_rack_app(schema: 7,)
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal "Committee: schema expected to be an instance of Committee::Drivers::Schema.", e.message
  end

  it "errors when no schema is specified" do
    @app = new_rack_app
    e = assert_raises(ArgumentError) do
      post "/apps"
    end

    assert_equal "Committee: need option `schema` or `schema_path`", e.message
  end

  describe 'initialize option' do
    it "accepts OpenAPI3 parser config of strict_reference_validation and raises" do
      assert_raises(OpenAPIParser::MissingReferenceError) do
        Committee::Middleware::Base.new(nil, schema_path: open_api_3_invalid_reference_path, strict_reference_validation: true)
      end
    end

    it "does not raise by default even with invalid reference OpenAPI3 specification" do
      b = Committee::Middleware::Base.new(nil, schema_path: open_api_3_invalid_reference_path, strict_reference_validation: false)
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, b.instance_variable_get(:@schema)
    end
  end

  describe 'Options instances' do
    it "loads a schema path from Base options" do
      options = Committee::Middleware::Options::Base.new(schema_path: open_api_3_schema_path, strict_reference_validation: false)

      middleware = Committee::Middleware::Base.new(nil, options)

      assert_kind_of Committee::Drivers::OpenAPI3::Schema, middleware.instance_variable_get(:@schema)
    end

    it "preserves OpenAPI3 request defaults and routing with RequestValidation options" do
      options_hash = { schema: open_api_3_1_schema, prefix: '/v1' }
      [options_hash, Committee::Middleware::Options::RequestValidation.new(options_hash)].each do |options|
        check_params = lambda { |env|
          assert_equal 5, env['committee.query_hash']['limit']
          assert_equal [1, 2], env['committee.query_hash']['ids']
          [200, {}, []]
        }
        @app = Rack::Builder.new {
          use Committee::Middleware::RequestValidation, options
          run check_params
        }

        status, _headers, _body = @app.call(Rack::MockRequest.env_for('/v1/search?limit=5&ids=1,2'))

        assert_equal 200, status
      end
    end

    it "preserves the HyperSchema GET body default with RequestValidation options" do
      options_hash = { schema: hyper_schema }
      [options_hash, Committee::Middleware::Options::RequestValidation.new(options_hash)].each do |options|
        @app = new_rack_app(options)

        env = Rack::MockRequest.env_for('/search/apps', method: 'GET', input: JSON.generate(query: 'cloudnasium'), 'CONTENT_TYPE' => 'application/json')
        status, _headers, _body = @app.call(env)

        assert_equal 200, status
      end
    end

    it "loads and routes with ResponseValidation options and preserves explicit flags" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema_path: open_api_3_schema_path, strict_reference_validation: false, prefix: '/v1', validate_success_only: false)
      @app = Rack::Builder.new {
        use Committee::Middleware::ResponseValidation, options
        run ->(_) { [422, { 'Content-Type' => 'application/json' }, ['not_json']] }
      }

      get '/v1/characters'
      assert_equal 500, last_response.status

      get '/characters'
      assert_equal 422, last_response.status
    end
  end

  private

  def new_rack_app(options = {})
    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run lambda { |_|
        [200, {}, []]
      }
    }
  end
end

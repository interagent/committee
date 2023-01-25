# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Base do
  include Rack::Test::Methods

  def app
    @app
  end

  it "accepts just a schema object" do
    @app = new_rack_app(
      schema: hyper_schema
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts just a OpenAPI3 schema object" do
    @app = new_rack_app(schema: open_api_3_schema)
    params = {
        "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "doesn't accept a schema string" do
    @app = new_rack_app(
      schema: JSON.dump(hyper_schema_data)
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " +
                     "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept a schema hash" do
    @app = new_rack_app(
      schema: hyper_schema_data
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " +
                     "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept a JsonSchema::Schema object" do
    @app = new_rack_app(
      schema: JsonSchema.parse!(hyper_schema_data)
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"

    e = assert_raises(ArgumentError) do
      post "/apps", JSON.generate(params)
    end

    assert_equal "Committee: schema expected to be an instance " +
                     "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept other schema types" do
    @app = new_rack_app(
      schema: 7,
    )
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

  private

  def new_rack_app(options = {})
    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil

    Rack::Builder.new {
      use Committee::Middleware::RequestValidation, options
      run lambda { |_|
        [200, {}, []]
      }
    }
  end
end

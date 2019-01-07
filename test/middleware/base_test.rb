require_relative "../test_helper"

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

  it "don't accepts schema string" do
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

  it "don't accepts schema hash" do
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

  it "don't accepts schema JsonSchema::Schema object" do
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

    assert_equal "Committee: schema expected to be an instance " +
                     "of Committee::Drivers::Schema.", e.message
  end

  it "schema not exist" do
    @app = new_rack_app
    e = assert_raises(ArgumentError) do
      post "/apps"
    end

    assert_equal "Committee: need option `schema` or `json_file` or `yaml_file`", e.message
  end

  describe 'initialize option' do
    it "json file option with hyper-schema" do
      b = Committee::Middleware::Base.new(nil, json_file: hyper_schema_filepath)
      assert_kind_of Committee::Drivers::HyperSchema::Schema, b.instance_variable_get(:@schema)
    end

    it "json file option with OpenAPI2" do
      b = Committee::Middleware::Base.new(nil, json_file: open_api_2_filepath)
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, b.instance_variable_get(:@schema)
    end

    it "yaml file option with OpenAPI2" do
      b = Committee::Middleware::Base.new(nil, yaml_file: open_api_3_filepath)
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, b.instance_variable_get(:@schema)
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

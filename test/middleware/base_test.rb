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
    @app = new_rack_app(open_api_3: open_api_3_schema)
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

    assert_equal "Committee: need option `schema` or `open_api_3`", e.message
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

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

  it "accepts driver and schema objects" do
    driver = Committee::Drivers::HyperSchema.new
    schema = driver.parse(hyper_schema_data)

    @app = new_rack_app(
      driver: driver,
      schema: schema,
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts driver name and schema hash" do
    @app = new_rack_app(
      driver: :hyper_schema,
      schema: hyper_schema_data,
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts driver name and JsonSchema::Schema object (legacy behavior)" do
    schema = JsonSchema.parse!(hyper_schema_data)
    @app = new_rack_app(
      driver: :hyper_schema,
      schema: schema
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "doesn't accept other driver types" do
    @app = new_rack_app(
      driver: "hello"
    )
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal "Committee: driver expected to be a symbol or an instance " +
      "of Committee::Drivers::Driver.", e.message
  end

  it "doesn't accept other schema types" do
    @app = new_rack_app(
      driver: :hyper_schema,
      schema: 7,
    )
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal "Committee: schema expected to be a hash or an instance " +
      "of Committee::Drivers::Schema.", e.message
  end

  it "doesn't accept schema object for non-hyper-schema driver" do
    schema = JsonSchema.parse!(hyper_schema_data)
    @app = new_rack_app(
      driver: :open_api_2,
      schema: schema
    )
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal "Committee: JSON schema data is only accepted for driver " \
      "hyper_schema. Try passing a hash instead.", e.message
  end

  it "complains on unknown driver" do
    @app = new_rack_app(
      driver: :blueprint
    )
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal %{Committee: unknown driver "blueprint".}, e.message
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

require_relative "../test_helper"

describe Committee::Middleware::Base do
  include Rack::Test::Methods

  def app
    @app
  end

  it "accepts schema hash" do
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

  it "accepts schema object" do
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

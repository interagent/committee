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

  it "accepts schema string (legacy behavior)" do
    mock(Committee).warn_deprecated.with_any_args
    @app = new_rack_app(
      schema: JSON.dump(hyper_schema_data)
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts schema hash (legacy behavior)" do
    mock(Committee).warn_deprecated.with_any_args
    @app = new_rack_app(
      schema: hyper_schema_data
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "accepts schema JsonSchema::Schema object (legacy behavior)" do
    # Note we don't warn here because this is a recent deprecation and passing
    # a schema object will not be a huge performance hit. We should probably
    # start warning on the next version.

    @app = new_rack_app(
      schema: JsonSchema.parse!(hyper_schema_data)
    )
    params = {
      "name" => "cloudnasium"
    }
    header "Content-Type", "application/json"
    post "/apps", JSON.generate(params)
    assert_equal 200, last_response.status
  end

  it "doesn't accept other schema types" do
    @app = new_rack_app(
      schema: 7,
    )
    e = assert_raises(ArgumentError) do
      post "/apps"
    end
    assert_equal "Committee: schema expected to be a hash or an instance " +
      "of Committee::Drivers::Schema.", e.message
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

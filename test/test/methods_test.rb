require_relative "../test_helper"

describe Committee::Test::Methods do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    @app
  end

  def committee_options
    @committee_options
  end

  def request_object
    last_request
  end

  def response_data
    [last_response.status, last_response.headers, last_response.body]
  end

  before do
    # This is a little icky, but the test methods will cache router and schema
    # values between tests. This makes sense in real life, but is harmful for
    # our purposes here in testing the module.
    @committee_router = nil
    @committee_schema = nil
    @committee_options = nil
    @validate_errors = nil
  end

  describe "Hyper-Schema" do
    before do
      sc = JsonSchema.parse!(hyper_schema_data)
      sc.expand_references!
      s = Committee::Drivers::HyperSchema.new.parse(sc)
      @committee_options = {schema: s}
    end

    describe "#assert_schema_conform" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate([ValidApp]))
        get "/apps"
        assert_schema_conform
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([ValidApp]), {})
        get "/apps"
        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform
        end
        assert_match(/response header must be set to/i, e.message)
      end
    end
  end

  describe "OpenAPI3" do
    before do
      @committee_options = {open_api_3: open_api_3_schema}

      @correct_response = { string_1: :honoka }
    end

    describe "#assert_schema_conform" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate(@correct_response))
        get "/characters"
        assert_schema_conform
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([@correct_response]), {})
        get "/characters"
        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform
        end
        assert_match(/don't exist response definition/i, e.message)
      end

      it "detects an invalid response status code" do
        @committee_options.merge!(validate_errors: true)
        @app = new_rack_app(JSON.generate([@correct_response]), {}, 419)

        get "/characters"

        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform
        end
        assert_match(/don't exist status code definition/i, e.message)
      end

      it "detects an invalid response status code with validate_errors = false" do
        @committee_options.merge!(validate_errors: false)
        @app = new_rack_app(JSON.generate([@correct_response]), {}, 419)

        get "/characters"

        assert_schema_conform
      end
    end
  end

  private

  def new_rack_app(response, headers={ "Content-Type" => "application/json" }, status_code = 200)
    Rack::Builder.new {
      run lambda { |_|
        [status_code, headers, [response]]
      }
    }
  end
end

require_relative "../test_helper"

describe Committee::Middleware::Stub do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    @app
  end

  def schema_path
    "./test/data/hyperschema/paas.json"
  end

  describe "#assert_schema_content_type" do
    it "warns about deprecation" do
      mock(Committee).warn_deprecated.with_any_args
      assert_schema_content_type
    end
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
      assert_match /response header must be set to/i, e.message
    end

    it "warns when sending a deprecated string" do
      stub(self).schema_contents { File.read(schema_path) }
      mock(Committee).warn_deprecated.with_any_args
      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/apps"
      assert_schema_conform
    end
  end

  private

  def new_rack_app(response, headers={ "Content-Type" => "application/json" })
    Rack::Builder.new {
      run lambda { |_|
        [200, headers, [response]]
      }
    }
  end
end

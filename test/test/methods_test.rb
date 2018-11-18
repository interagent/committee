require_relative "../test_helper"

describe Committee::Test::Methods do
  include Committee::Test::Methods
  include Rack::Test::Methods

  def app
    @app
  end

  def committee_schema
    hyper_schema
  end

  before do
    # This is a little icky, but the test methods will cache router and schema
    # values between tests. This makes sense in real life, but is harmful for
    # our purposes here in testing the module.
    @committee_router = nil
    @committee_schema = nil
  end

  describe "#assert_schema_content_type" do
    it "warns about deprecation" do
      mock(Committee).warn_deprecated.with_any_args
      assert_schema_content_type
    end
  end

  describe "#assert_schema_conform" do
    it "passes through a valid response" do
      mock(Committee).warn_deprecated.with_any_args.times(3)

      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/apps"
      assert_schema_conform
    end

    it "detects an invalid response Content-Type" do
      mock(Committee).warn_deprecated.with_any_args.times(3)

      @app = new_rack_app(JSON.generate([ValidApp]), {})
      get "/apps"
      e = assert_raises(Committee::InvalidResponse) do
        assert_schema_conform
      end
      assert_match(/response header must be set to/i, e.message)
    end

    it "accepts schema string (legacy behavior)" do
      mock(Committee).warn_deprecated.with_any_args.times(4)

      stub(self).committee_schema { nil }
      stub(self).schema_contents { JSON.dump(hyper_schema_data) }

      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/apps"
      assert_schema_conform
    end

    it "accepts schema hash (legacy behavior)" do
      mock(Committee).warn_deprecated.with_any_args.times(4)

      stub(self).committee_schema { nil }
      stub(self).schema_contents { hyper_schema_data }

      @app = new_rack_app(JSON.generate([ValidApp]))
      get "/apps"
      assert_schema_conform
    end

    it "accepts schema JsonSchema::Schema object (legacy behavior)" do
      # Note we don't warn here because this is a recent deprecation and
      # passing a schema object will not be a huge performance hit. We should
      # probably start warning on the next version.
      mock(Committee).warn_deprecated.with_any_args.times(3)

      stub(self).committee_schema { nil }
      stub(self).schema_contents do
        schema = JsonSchema.parse!(hyper_schema_data)
        schema.expand_references!
        schema
      end

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

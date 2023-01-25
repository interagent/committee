# frozen_string_literal: true

require "test_helper"

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
    @committee_options = {}

    # TODO: delete when 5.0.0 released because default value changed
    @committee_options[:parse_response_by_content_type] = true
  end

  describe "Hyper-Schema" do
    before do
      sc = JsonSchema.parse!(hyper_schema_data)
      sc.expand_references!
      s = Committee::Drivers::HyperSchema::Driver.new.parse(sc)
      @committee_options.merge!({schema: s})
    end

    describe "#assert_schema_conform" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate([ValidApp]))
        get "/apps"
        assert_schema_conform(200)
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([ValidApp]), {})
        get "/apps"
        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform(200)
        end
        assert_match(/response header must be set to/i, e.message)
      end
    end

    describe "assert_request_schema_confirm" do
      it "passes through a valid request" do
        @app = new_rack_app([])
        get "/apps"
        assert_request_schema_confirm
      end

      it "not exist required" do
        @app = new_rack_app([])
        get "/search/apps", {}
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end
        assert_match(/"query" wasn't supplied\./i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app([])
        get "/undefined"
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end
        assert_match(/`GET \/undefined` undefined in schema/i, e.message)
      end
    end

    describe "#assert_response_schema_confirm" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate([ValidApp]))
        get "/apps"
        assert_response_schema_confirm(200)
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([ValidApp]), {})
        get "/apps"
        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm(200)
        end
        assert_match(/response header must be set to/i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app(JSON.generate([ValidApp]))
        get "/undefined"
        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm
        end
        assert_match(/`GET \/undefined` undefined in schema/i, e.message)
      end
    end
  end

  describe "OpenAPI3" do
    before do
      @committee_options.merge!({schema: open_api_3_schema})

      @correct_response = { string_1: :honoka }
    end

    describe "#assert_schema_conform" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate(@correct_response))
        get "/characters"
        assert_schema_conform(200)
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([@correct_response]), {})
        get "/characters"
        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform(200)
        end
        assert_match(/response definition does not exist/i, e.message)
      end

      it "detects an invalid response status code" do
        @app = new_rack_app(JSON.generate([@correct_response]), {}, 419)

        get "/characters"

        e = assert_raises(Committee::InvalidResponse) do
          assert_schema_conform(419)
        end
        assert_match(/status code definition does not exist/i, e.message)
      end
    end

    describe "assert_request_schema_confirm" do
      it "passes through a valid request" do
        @app = new_rack_app([])
        get "/characters"
        assert_request_schema_confirm
      end

      it "not exist required" do
        @app = new_rack_app([])
        get "/validate", {"query_string" => "query", "query_integer_list" => [1, 2]}
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end

        assert_match(/missing required parameters: query_string/i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app([])
        get "/undefined"
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end
        assert_match(/`GET \/undefined` undefined in schema/i, e.message)
      end
    end

    describe "#assert_response_schema_confirm" do
      it "passes through a valid response" do
        @app = new_rack_app(JSON.generate(@correct_response))
        get "/characters"
        assert_response_schema_confirm(200)
      end

      it "detects an invalid response Content-Type" do
        @app = new_rack_app(JSON.generate([@correct_response]), {})
        get "/characters"
        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm(200)
        end
        assert_match(/response definition does not exist/i, e.message)
      end

      it "detects an invalid response status code" do
        @app = new_rack_app(JSON.generate([@correct_response]), {}, 419)

        get "/characters"

        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm(419)
        end
        assert_match(/status code definition does not exist/i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app(JSON.generate(@correct_response))
        get "/undefined"
        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm
        end
        assert_match(/`GET \/undefined` undefined in schema/i, e.message)
      end

      it "raises error when path does not match prefix" do
        @committee_options.merge!({prefix: '/api'})
        @app = new_rack_app(JSON.generate(@correct_response))
        get "/characters"
        e = assert_raises(Committee::InvalidResponse) do
          assert_response_schema_confirm
        end
        assert_match(/`GET \/characters` undefined in schema \(prefix: "\/api"\)/i, e.message)
      end

      describe 'coverage' do
        before do
          @schema_coverage = Committee::Test::SchemaCoverage.new(open_api_3_coverage_schema)
          @committee_options.merge!(schema: open_api_3_coverage_schema, schema_coverage: @schema_coverage)

          @app = new_rack_app(JSON.generate({ success: true }))
        end
        it 'records openapi coverage' do
          get "/posts"
          assert_response_schema_confirm(200)
          assert_equal({
            '/threads/{id}' => {
              'get' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
            '/posts' => {
              'get' => {
                'responses' => {
                  '200' => true,
                  '404' => false,
                  'default' => false,
                },
              },
              'post' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
            '/likes' => {
              'post' => {
                'responses' => {
                  '200' => false,
                },
              },
              'delete' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
          }, @schema_coverage.report)
        end

        it 'can record openapi coverage correctly when prefix is set' do
          @committee_options.merge!(prefix: '/api')
          post "/api/likes"
          assert_response_schema_confirm(200)
          assert_equal({
            '/threads/{id}' => {
              'get' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
            '/posts' => {
              'get' => {
                'responses' => {
                  '200' => false,
                  '404' => false,
                  'default' => false,
                },
              },
              'post' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
            '/likes' => {
              'post' => {
                'responses' => {
                  '200' => true,
                },
              },
              'delete' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
          }, @schema_coverage.report)
        end

        it 'records openapi coverage correctly with path param' do
          get "/threads/asd"
          assert_response_schema_confirm(200)
          assert_equal({
            '/threads/{id}' => {
              'get' => {
                'responses' => {
                  '200' => true,
                },
              },
            },
            '/posts' => {
              'get' => {
                'responses' => {
                  '200' => false,
                  '404' => false,
                  'default' => false,
                },
              },
              'post' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
            '/likes' => {
              'post' => {
                'responses' => {
                  '200' => false,
                },
              },
              'delete' => {
                'responses' => {
                  '200' => false,
                },
              },
            },
          }, @schema_coverage.report)
        end
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

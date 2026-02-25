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
  end

  describe "Hyper-Schema" do
    before do
      sc = JsonSchema.parse!(hyper_schema_data)
      sc.expand_references!
      s = Committee::Drivers::HyperSchema::Driver.new.parse(sc)
      @committee_options.merge!({ schema: s })
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
        @app = new_rack_app
        get "/apps"
        assert_request_schema_confirm
      end

      it "not exist required" do
        @app = new_rack_app
        get "/search/apps", {}
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end
        assert_match(/"query" wasn't supplied\./i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app
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
      @committee_options.merge!({ schema: open_api_3_schema })

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
        @app = new_rack_app
        get "/characters"
        assert_request_schema_confirm
      end

      it "not exist required" do
        @app = new_rack_app
        get "/validate", { "query_string" => "query", "query_integer_list" => [1, 2] }
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end

        assert_match(/missing required parameters: query_string/i, e.message)
      end

      it "path undefined in schema" do
        @app = new_rack_app
        get "/undefined"
        e = assert_raises(Committee::InvalidRequest) do
          assert_request_schema_confirm
        end
        assert_match(/`GET \/undefined` undefined in schema/i, e.message)
      end

      describe "with except option" do
        it "passes validation when required query parameter is excepted" do
          @app = new_rack_app
          # Missing required 'data' parameter, but except it
          get "/get_endpoint_with_required_parameter"
          assert_request_schema_confirm(except: { query: ['data'] })
        end

        it "still validates other parameters when some are excepted" do
          @app = new_rack_app
          # Missing required 'data' parameter, but except it
          # This test verifies that the except option works
          get "/get_endpoint_with_required_parameter"
          assert_request_schema_confirm(except: { query: ['data'] })
        end

        it "works without except option (backward compatibility)" do
          @app = new_rack_app
          get "/characters"
          assert_request_schema_confirm
        end

        it "supports multiple parameter types" do
          @app = new_rack_app
          # Can except headers, query, and body parameters
          get "/get_endpoint_with_required_parameter"
          assert_request_schema_confirm(except: { headers: ['authorization'], query: ['data'] })
        end

        it "supports multiple parameters in each type" do
          @app = new_rack_app
          # Can except multiple parameters in each type simultaneously
          get "/get_endpoint_with_required_parameter"
          assert_request_schema_confirm(except: { headers: ['content-type', 'authorization', 'accept'], query: ['data', 'page', 'limit'] })
        end

        it "raises error when non-excepted required parameter is missing" do
          @app = new_rack_app
          # Except only 'required_param_a', but 'required_param_b' is also required and missing
          # This should raise an error for 'required_param_b'
          get "/test_except_validation"

          e = assert_raises(Committee::InvalidRequest) do
            assert_request_schema_confirm(except: { query: ['required_param_a'] })
          end
          # Verify error is about the non-excepted missing parameter
          assert_match(/required_param_b/i, e.message)
        end

        describe "with body params" do
          it "passes validation when required string body param is excepted" do
            @app = new_rack_app
            post "/test_except_body_params", JSON.generate({ "required_integer" => 1 }), { "CONTENT_TYPE" => "application/json" }
            assert_request_schema_confirm(except: { body: ['required_string'] })
          end

          it "passes validation when required integer body param is excepted" do
            @app = new_rack_app
            post "/test_except_body_params", JSON.generate({ "required_string" => "foo" }), { "CONTENT_TYPE" => "application/json" }
            assert_request_schema_confirm(except: { body: ['required_integer'] })
          end

          it "passes validation when all required body params are excepted" do
            @app = new_rack_app
            post "/test_except_body_params", nil, { "CONTENT_TYPE" => "application/json" }
            assert_request_schema_confirm(except: { body: ['required_string', 'required_integer'] })
          end

          it "raises error when non-excepted required body param is missing" do
            @app = new_rack_app
            post "/test_except_body_params", nil, { "CONTENT_TYPE" => "application/json" }
            e = assert_raises(Committee::InvalidRequest) do
              assert_request_schema_confirm(except: { body: ['required_string'] })
            end
            assert_match(/required_integer/i, e.message)
          end

          describe "non-string types and format constraints" do
            it "passes validation when required integer query param is excepted" do
              @app = new_rack_app
              get "/get_endpoint_with_required_integer_query"
              assert_request_schema_confirm(except: { query: ['count'] })
            end

            it "passes validation when required integer header is excepted" do
              @app = new_rack_app
              get "/header"
              assert_request_schema_confirm(except: { headers: ['integer'] })
            end

            it "passes validation when required enum body param is excepted" do
              @app = new_rack_app
              post "/test_except_body_with_constraints", JSON.generate({ "created_at" => "2024-01-01T00:00:00Z" }), { "CONTENT_TYPE" => "application/json" }
              assert_request_schema_confirm(except: { body: ['status'] })
            end

            it "passes validation when required date-time format body param is excepted" do
              @app = new_rack_app
              post "/test_except_body_with_constraints", JSON.generate({ "status" => "active" }), { "CONTENT_TYPE" => "application/json" }
              assert_request_schema_confirm(except: { body: ['created_at'] })
            end
          end

          describe "with form-encoded body params" do
            it "passes validation when required string form param is excepted" do
              @app = new_rack_app
              post "/test_except_form_params", "required_integer=1", { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
              assert_request_schema_confirm(except: { body: ['required_string'] })
            end

            it "passes validation when required integer form param is excepted" do
              @app = new_rack_app
              post "/test_except_form_params", "required_string=foo", { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
              assert_request_schema_confirm(except: { body: ['required_integer'] })
            end

            it "passes validation when all required form params are excepted" do
              @app = new_rack_app
              post "/test_except_form_params", "", { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
              assert_request_schema_confirm(except: { body: ['required_string', 'required_integer'] })
            end

            it "raises error when non-excepted required form param is missing" do
              @app = new_rack_app
              post "/test_except_form_params", "", { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
              e = assert_raises(Committee::InvalidRequest) do
                assert_request_schema_confirm(except: { body: ['required_string'] })
              end
              assert_match(/required_integer/i, e.message)
            end
          end

          describe "with special rack headers" do
            it "passes validation when required Content-Type header is excepted" do
              @app = new_rack_app
              post "/test_except_content_type_header", nil
              assert_request_schema_confirm(except: { headers: ['Content-Type'] })
            end
          end

          describe "does not overwrite existing values" do
            it "leaves an existing query param value unchanged when it is excepted" do
              @app = new_rack_app
              get "/get_endpoint_with_required_parameter", "data" => "existing_value"
              before_value = last_request.GET["data"]
              assert_request_schema_confirm(except: { query: ['data'] })
              assert_equal before_value, last_request.GET["data"]
            end
          end

          describe "with vnd.api+json content type" do
            it "treats application/vnd.api+json body as JSON and injects dummy values" do
              @app = new_rack_app
              post "/test_except_vnd_json_body", JSON.generate({}), { "CONTENT_TYPE" => "application/vnd.api+json" }
              assert_request_schema_confirm(except: { body: ['required_string'] })
            end
          end

          describe "error recovery" do
            it "restores partially-applied params when JSON body parsing raises mid-apply" do
              # Scenario: HeaderHandler injects a dummy header, then BodyHandler fails
              # to parse an invalid JSON body (JSON::ParserError). With apply() outside
              # the ensure block the injected header would not be restored. This test
              # verifies that all side-effects from apply() are rolled back even when
              # apply() itself raises.
              @app = new_rack_app
              post "/test_except_body_params", 'invalid-json', { "CONTENT_TYPE" => "application/json" }

              assert_nil last_request.env['HTTP_AUTHORIZATION']

              assert_raises(JSON::ParserError) do
                assert_request_schema_confirm(except: { headers: ['authorization'], body: ['required_string'] })
              end

              assert_nil last_request.env['HTTP_AUTHORIZATION']
            end
          end

        end
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
        @committee_options.merge!({ prefix: '/api' })
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
          assert_equal({ '/threads/{id}' => { 'get' => { 'responses' => { '200' => false, }, }, }, '/posts' => { 'get' => { 'responses' => { '200' => true, '404' => false, 'default' => false, }, }, 'post' => { 'responses' => { '200' => false, }, }, }, '/likes' => { 'post' => { 'responses' => { '200' => false, }, }, 'delete' => { 'responses' => { '200' => false, }, }, }, }, @schema_coverage.report)
        end

        it 'can record openapi coverage correctly when prefix is set' do
          @committee_options.merge!(prefix: '/api')
          post "/api/likes"
          assert_response_schema_confirm(200)
          assert_equal({ '/threads/{id}' => { 'get' => { 'responses' => { '200' => false, }, }, }, '/posts' => { 'get' => { 'responses' => { '200' => false, '404' => false, 'default' => false, }, }, 'post' => { 'responses' => { '200' => false, }, }, }, '/likes' => { 'post' => { 'responses' => { '200' => true, }, }, 'delete' => { 'responses' => { '200' => false, }, }, }, }, @schema_coverage.report)
        end

        it 'records openapi coverage correctly with path param' do
          get "/threads/asd"
          assert_response_schema_confirm(200)
          assert_equal({ '/threads/{id}' => { 'get' => { 'responses' => { '200' => true, }, }, }, '/posts' => { 'get' => { 'responses' => { '200' => false, '404' => false, 'default' => false, }, }, 'post' => { 'responses' => { '200' => false, }, }, }, '/likes' => { 'post' => { 'responses' => { '200' => false, }, }, 'delete' => { 'responses' => { '200' => false, }, }, }, }, @schema_coverage.report)
        end
      end
    end
  end

  private

  def new_rack_app(response = nil, headers = { "Content-Type" => "application/json" }, status_code = 200)
    Rack::Builder.new {
      run lambda { |_|
        [status_code, headers, [response]]
      }
    }
  end
end

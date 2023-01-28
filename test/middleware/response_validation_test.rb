# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::ResponseValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "passes through a valid response" do
    @app = new_rack_app(JSON.generate([ValidApp]), {}, schema: hyper_schema)
    get "/apps"
    assert_equal 200, last_response.status
  end

  # TODO: remove 5.0.0
  it "passes through a valid response" do
    # will show deprecated message
    @app = new_rack_app(JSON.generate([ValidApp]), {}, schema: hyper_schema, strict: true)
    get "/apps"
    assert_equal 200, last_response.status
  end

  it "doesn't call error_handler (has a arg) when response is valid" do
    called = false
    pr = ->(_e) { called = true }
    @app = new_rack_app(JSON.generate([ValidApp]), {}, schema: hyper_schema, error_handler: pr)
    get "/apps"
    assert !called, "error_handler is called"
  end

  it "doesn't call error_handler (has two args) when response is valid" do
    called = false
    pr = ->(_e, _env) { called = true }
    @app = new_rack_app(JSON.generate([ValidApp]), {}, schema: hyper_schema, error_handler: pr)
    get "/apps"
    assert !called, "error_handler is called"
  end

  it "detects a response invalid due to schema" do
    @app = new_rack_app("{}", {}, schema: hyper_schema)
    get "/apps"
    assert_equal 500, last_response.status
    assert_match(/{} is not an array/i, last_response.body)
  end

  it "detects a response invalid due to schema with ignore_error option" do
    @app = new_rack_app("{}", {}, schema: hyper_schema, ignore_error: true)
    get "/apps"
    assert_equal 200, last_response.status
  end

  it "detects a response invalid due to not being JSON" do
    @app = new_rack_app("{_}", {}, schema: hyper_schema)
    get "/apps"
    assert_equal 500, last_response.status
    assert_match(/valid JSON/i, last_response.body)
  end

  it "ignores a non-2xx invalid response" do
    @app = new_rack_app("[]", {}, app_status: 404, schema: hyper_schema)
    get "/apps"
    assert_equal 404, last_response.status
  end

  it "optionally validates non-2xx invalid responses" do
    @app = new_rack_app("", {}, app_status: 404, validate_success_only: false, schema: hyper_schema)
    get "/apps"
    assert_equal 500, last_response.status
    assert_match(/Invalid response/i, last_response.body)
  end

  it "optionally validates non-2xx invalid responses with invalid json" do
    @app = new_rack_app("{_}", {}, app_status: 404, validate_success_only: false, schema: hyper_schema)
    get "/apps"
    assert_equal 500, last_response.status
    assert_match(/valid JSON/i, last_response.body)
  end

  it "passes through a 204 (no content) response" do
    @app = new_rack_app("", {}, app_status: 204, schema: hyper_schema)
    get "/apps"
    assert_equal 204, last_response.status
  end

  it "passes through a 304 (not modified) response" do
    @app = new_rack_app("", {}, app_status: 304, schema: hyper_schema)
    get "/apps"
    assert_equal 304, last_response.status
  end

  it "skip validation when 4xx" do
    @app = new_rack_app("[{x:y}]", {}, schema: hyper_schema, validate_success_only: true, app_status: 400)
    get "/apps"
    assert_equal 400, last_response.status
    assert_match("[{x:y}]", last_response.body)
  end

  it "rescues JSON errors" do
    @app = new_rack_app("[{x:y}]", {}, schema: hyper_schema, validate_success_only: false)
    get "/apps"
    assert_equal 500, last_response.status
    assert_match(/valid json/i, last_response.body)
  end

  it "calls error_handler (has two args) when it rescues JSON errors" do
    called_err = nil
    pr = ->(e, _env) { called_err = e }
    @app = new_rack_app("[{x:y}]", {}, schema: hyper_schema, error_handler: pr)
    get "/apps"
    assert_kind_of JSON::ParserError, called_err
  end

  it "takes a prefix" do
    @app = new_rack_app(JSON.generate([ValidApp]), {}, prefix: "/v1",
      schema: hyper_schema)
    get "/v1/apps"
    assert_equal 200, last_response.status
  end

  it "rescues JSON errors" do
    @app = new_rack_app("[{x:y}]", {}, raise: true, schema: hyper_schema)
    assert_raises(Committee::InvalidResponse) do
      get "/apps"
    end
  end

  it "calls error_handler (has two args) when it rescues JSON errors" do
    called_err = nil
    pr = ->(e, _env) { called_err = e }
    @app = new_rack_app("[{x:y}]", {}, raise: true, schema: hyper_schema, error_handler: pr)
    assert_raises(Committee::InvalidResponse) do
      get "/apps"
      assert_kind_of JSON::ParserError, called_err
    end
  end

  it "passes through a valid response for OpenAPI" do
    @app = new_rack_app(JSON.generate([ValidPet]), {},
      schema: open_api_2_schema)
    get "/api/pets"
    assert_equal 200, last_response.status
  end

  it "detects an invalid response for OpenAPI" do
    @app = new_rack_app("{_}", {}, schema: open_api_2_schema)
    get "/api/pets"
    assert_equal 500, last_response.status
    assert_match(/valid JSON/i, last_response.body)
  end

  describe ':accept_request_filter' do
    [
      { description: 'when not specified, includes everything', accept_request_filter: nil, expected: { status: 500 } },
      { description: 'when predicate matches, performs validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/a') }, expected: { status: 500 } },
      { description: 'when predicate does not match, skips validation', accept_request_filter: -> (request) { request.path.start_with?('/v1/x') }, expected: { status: 200 } },
    ].each do |h|
      description = h[:description]
      accept_request_filter = h[:accept_request_filter]
      expected = h[:expected]
      it description do
        @app = new_rack_app('not_json', {}, schema: hyper_schema, prefix: '/v1', accept_request_filter: accept_request_filter)

        get '/v1/apps'

        assert_equal expected[:status], last_response.status
      end
    end
  end

  private

  def new_rack_app(response, headers = {}, options = {})
    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil

    headers = {
      "Content-Type" => "application/json"
    }.merge(headers)
    Rack::Builder.new {
      use Committee::Middleware::ResponseValidation, options
      run lambda { |_|
        [options.fetch(:app_status, 200), headers, [response]]
      }
    }
  end
end

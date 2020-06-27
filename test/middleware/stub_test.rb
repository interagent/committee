# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Stub do
  include Rack::Test::Methods

  def app
    @app
  end

  it "responds with a stubbed response" do
    @app = new_rack_app(schema: hyper_schema)
    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end

  it "responds with 201 on create actions" do
    @app = new_rack_app(schema: hyper_schema)
    post "/apps"
    assert_equal 201, last_response.status
  end

  it "optionally calls into application" do
    @app = new_rack_app(call: true, schema: hyper_schema)
    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    assert_equal ValidApp,
      JSON.parse(last_response.headers["Committee-Response"])
  end

  it "optionally returns the application's response" do
    @app = new_rack_app(call: true, schema: hyper_schema, suppress: true)
    get "/apps/heroku-api"
    assert_equal 429, last_response.status
    assert_equal ValidApp,
      JSON.parse(last_response.headers["Committee-Response"])
    assert_equal "", last_response.body
  end

  it "optionally returns the application's response schema" do
    @app = new_rack_app(call: true, schema: hyper_schema, suppress: true)
    get "/apps/heroku-api"
    assert_equal 429, last_response.status
    assert_equal "#/definitions/app/links/2/targetSchema",
      last_response.headers["Committee-Response-Schema"]
    assert_equal "", last_response.body
  end

  it "takes a prefix" do
    @app = new_rack_app(prefix: "/v1", schema: hyper_schema)
    get "/v1/apps/heroku-api"
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert_equal ValidApp.keys.sort, data.keys.sort
  end

  it "allows the stub's response to be replaced" do
    response = { replaced: true }
    @app = new_rack_app(call: true, response: response, schema: hyper_schema)
    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    assert_equal response, JSON.parse(last_response.body, symbolize_names: true)
  end

  it "responds with a stubbed response for OpenAPI" do
    @app = new_rack_app(schema: open_api_2_schema)
    get "/api/pets/fido"
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert_equal ValidPet.keys.sort, data.keys.sort
  end

  it "calls into app for links that are undefined" do
    @app = new_rack_app(call: false, schema: hyper_schema)
    post "/foos"
    assert_equal 429, last_response.status
  end

  it "caches the response if called multiple times" do
    cache = {}
    @app = new_rack_app(cache: cache, schema: hyper_schema)

    get "/apps/heroku-api"
    assert_equal 200, last_response.status

    data, _schema = cache[cache.first[0]]
    assert_equal ValidApp.keys.sort, data.keys.sort

    # replace what we have in the cache
    cache[cache.first[0]] = { "cached" => true }

    get "/apps/heroku-api"
    assert_equal 200, last_response.status
    data = JSON.parse(last_response.body)
    assert_equal({ "cached" => true }, data)
  end

  it "caches the response if called multiple times" do
    cache = {}
    @app = new_rack_app(cache: cache, schema: open_api_3_schema)

    assert_raises(Committee::OpenAPI3Unsupported) do
      get "/characters"
    end
  end

  private

  def new_rack_app(options = {})
    response = options.delete(:response)
    suppress = options.delete(:suppress)

    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil

    Rack::Builder.new {
      use Committee::Middleware::Stub, options
      run lambda { |env|
        if response
          env["committee.response"] = response
        end

        headers = {}
        if res = env["committee.response"]
          headers.merge!({
            "Committee-Response" => JSON.generate(res)
          })
        end

        if res = env["committee.response_schema"]
          headers.merge!({
            "Committee-Response-Schema" => res.pointer,
          })
        end

        env["committee.suppress"] = suppress

        [429, headers, []]
      }
    }
  end
end

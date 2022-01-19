# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::OpenAPI3::RequestValidator do
  describe 'OpenAPI3' do
    include Rack::Test::Methods

    def app
      @app
    end

    it "skip validation when link does not exist" do
      @app = new_rack_app(schema: open_api_3_schema)
      params = {}
      header "Content-Type", "application/json"
      post "/unknown", JSON.generate(params)
      assert_equal 200, last_response.status
    end

    it "optionally content_type check" do
      @app = new_rack_app(check_content_type: true, schema: open_api_3_schema)
      params = {
        "string_post_1" => "cloudnasium"
      }
      header "Content-Type", "text/html"
      post "/characters", JSON.generate(params)
      assert_equal 400, last_response.status

      body = JSON.parse(last_response.body)
      message =
          %{"Content-Type" request header must be set to "application/json".}

      assert_equal "bad_request", body['id']
      assert_equal message, body['message']
    end

    it "validates content_type" do
      @app = new_rack_app(check_content_type: true, schema: open_api_3_schema)
      params = {
        "string_post_1" => "cloudnasium"
      }
      header "Content-Type", "text/html"
      post "/validate_content_types", JSON.generate(params)
      assert_equal 400, last_response.status

      body = JSON.parse(last_response.body)
      message =
        %{"Content-Type" request header must be set to any of the following: ["application/json", "application/binary"].}

      assert_equal message, body['message']
    end

    it "optionally skip content_type check" do
      @app = new_rack_app(check_content_type: false, schema: open_api_3_schema)
      params = {
          "string_post_1" => "cloudnasium"
      }
      header "Content-Type", "text/html"
      post "/characters", JSON.generate(params)
      assert_equal 200, last_response.status
    end

    it "if not exist requestBody definition, skip content_type check" do
      @app = new_rack_app(check_content_type: true, schema: open_api_3_schema)
      params = {
          "string_post_1" => "cloudnasium"
      }
      header "Content-Type", "application/json"
      patch "/validate_no_parameter", JSON.generate(params)
      assert_equal 200, last_response.status
    end

    it "does not mix up parameters and requestBody" do
      @app = new_rack_app(check_content_type: true, schema: open_api_3_schema)
      params = {
          "last_name" => "Skywalker"
      }
      header "Content-Type", "application/json"
      post "/additional_properties?first_name=Luke", JSON.generate(params)
      assert_equal 200, last_response.status
    end

    def new_rack_app(options = {})
      # TODO: delete when 5.0.0 released because default value changed
      options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil
    
      Rack::Builder.new {
        use Committee::Middleware::RequestValidation, options
        run lambda { |_|
          [200, {}, []]
        }
      }
    end
  end
end

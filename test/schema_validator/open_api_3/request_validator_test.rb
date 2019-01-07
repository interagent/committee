require_relative "../../test_helper"

describe Committee::SchemaValidator::OpenAPI3::RequestValidator do
  describe 'OpenAPI3' do
    include Rack::Test::Methods

    def app
      @app
    end

    it "optionally content_type check" do
      @app = new_rack_app(check_content_type: true, schema: open_api_3_schema)
      params = {
          "string_post_1" => "cloudnasium"
      }
      header "Content-Type", "text/html"
      post "/characters", JSON.generate(params)
      assert_equal 400, last_response.status
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

    def new_rack_app(options = {})
      Rack::Builder.new {
        use Committee::Middleware::RequestValidation, options
        run lambda { |_|
          [200, {}, []]
        }
      }
    end
  end
end

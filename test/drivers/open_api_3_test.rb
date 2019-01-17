require_relative "../test_helper"

describe Committee::Drivers::OpenAPI3 do
  before do
    @driver = Committee::Drivers::OpenAPI3.new
  end

  it "has a name" do
    assert_equal :open_api_3, @driver.name
  end

  it "has a schema class" do
    assert_equal Committee::Drivers::OpenAPI3::Schema, @driver.schema_class
  end

  it "override methods" do
    parser = OpenAPIParser.parse(open_api_3_data)
    schema = @driver.parse(parser)

    assert_kind_of Committee::Drivers::OpenAPI3::Schema, schema
    assert_kind_of OpenAPIParser::Schemas::OpenAPI, schema.open_api
    assert_equal @driver, schema.driver
  end

  it "defaults to coercing form parameters" do
    assert_equal true, @driver.default_coerce_form_params
  end

  it "defaults to path parameters" do
    assert_equal true, @driver.default_path_params
  end

  it "defaults to query parameters" do
    assert_equal true, @driver.default_query_params
  end

  describe "Schema" do
    describe "#operation_object" do
      describe "path template" do
        it "get normal path" do
          obj = open_api_3_schema.operation_object("/path_template_test/no_template", "get")
          assert_equal "/path_template_test/no_template", obj.original_path
        end

        it "get template path" do
          obj = open_api_3_schema.operation_object("/path_template_test/test", "get")
          assert_equal "/path_template_test/{template_name}", obj.original_path
        end

        it "get nested template path" do
          obj = open_api_3_schema.operation_object("/path_template_test/abc/nested", "get")
          assert_equal "/path_template_test/{template_name}/nested", obj.original_path
          assert_equal({"template_name"=>"abc"}, obj.path_params)
        end

        it "get double nested template path" do
          obj = open_api_3_schema.operation_object("/path_template_test/test/nested/abc", "get")
          assert_equal "/path_template_test/{template_name}/nested/{nested_parameter}", obj.original_path
          assert_equal({"template_name"=>"test", "nested_parameter" => "abc"}, obj.path_params)
        end

        it "get twice nested template path" do
          obj = open_api_3_schema.operation_object("/path_template_test/test/abc", "get")
          assert_equal "/path_template_test/{template_name}/{nested_parameter}", obj.original_path
          assert_equal({"template_name"=>"test", "nested_parameter" => "abc"}, obj.path_params)
        end

        it "get twice nested concrete path" do
          obj = open_api_3_schema.operation_object("/path_template_test/test/abc/finish", "get")
          assert_equal "/path_template_test/{template_name}/{nested_parameter}/finish", obj.original_path
          assert_equal({"template_name"=>"test", "nested_parameter" => "abc"}, obj.path_params)
        end

        it "get ambiguous path" do
          obj = open_api_3_schema.operation_object("/ambiguous/no_template", "get")
          assert_equal "/{ambiguous}/no_template", obj.original_path
          assert_equal({"ambiguous"=>"ambiguous"}, obj.path_params)
        end
      end
    end
  end
end

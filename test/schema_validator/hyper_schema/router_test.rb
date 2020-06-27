# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::HyperSchema::Router do
  it "builds routes without parameters" do
    link, _ = hyper_schema_router.find_link("GET", "/apps")
    refute_nil link
  end

  it "builds routes with parameters" do
    link, _ = hyper_schema_router.find_link("GET", "/apps/123")
    refute_nil link
  end

  it "doesn't match anything on a /" do
    link, _ = hyper_schema_router.find_link("GET", "/")
    assert_nil link
  end

  it "takes a prefix" do
    # this is a sociopathic example
    link, _ = hyper_schema_router(prefix: "/kpi").find_link("GET", "/kpi/apps/123")
    refute_nil link
  end

  it "includes all paths without a prefix" do
    link, _ = hyper_schema_router.includes?("/")
    refute_nil link

    link, _ = hyper_schema_router.includes?("/apps")
    refute_nil link
  end

  it "only includes the prefix path with a prefix" do
    link, _ = hyper_schema_router(prefix: "/kpi").includes?("/")
    assert_nil link

    link, _ = hyper_schema_router(prefix: "/kpi").includes?("/kpi")
    refute_nil link

    link, _ = hyper_schema_router(prefix: "/kpi").includes?("/kpi/apps")
    refute_nil link
  end

  it "provides named parameters" do
    link, param_matches = open_api_2_router.find_link("GET", "/api/pets/fido")
    refute_nil link
    assert_equal '/api/pets/{id}', link.href
    assert_equal({ "id" => "fido" }, param_matches)
  end

  it "doesn't provide named parameters where none are available" do
    link, param_matches = open_api_2_router.find_link("GET", "/api/pets")
    refute_nil link
    assert_equal({}, param_matches)
  end

  it "finds a path which has fewer matches" do
    link, _ = open_api_2_router.find_link("GET", "/api/pets/dog")
    refute_nil link
    assert_equal '/api/pets/dog', link.href
  end

  it "fewer match not support in HyperSchema" do
    link, _ = hyper_schema_router.find_link("GET", "/apps/abc")
    refute_nil link
    assert_equal '/apps/{(%23%2Fdefinitions%2Fapp%2Fdefinitions%2Fname)}', link.href
  end

  def hyper_schema_router(options = {})
    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil
    schema = Committee::Drivers::HyperSchema::Driver.new.parse(hyper_schema_data)
    validator_option = Committee::SchemaValidator::Option.new(options, schema, :hyper_schema)

    Committee::SchemaValidator::HyperSchema::Router.new(schema, validator_option)
  end

  def open_api_2_router(options = {})
    # TODO: delete when 5.0.0 released because default value changed
    options[:parse_response_by_content_type] = true if options[:parse_response_by_content_type] == nil
    schema = Committee::Drivers::OpenAPI2::Driver.new.parse(open_api_2_data)
    validator_option = Committee::SchemaValidator::Option.new(options, schema, :hyper_schema)

    Committee::SchemaValidator::HyperSchema::Router.new(schema, validator_option)
  end
end

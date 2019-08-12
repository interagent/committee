# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers::HyperSchema::Driver do
  before do
    @driver = Committee::Drivers::HyperSchema::Driver.new
  end

  it "has a name" do
    assert_equal :hyper_schema, @driver.name
  end

  it "has a schema class" do
    assert_equal Committee::Drivers::HyperSchema::Schema, @driver.schema_class
  end

  it "parses a hyper-schema and builds routes" do
    schema = @driver.parse(hyper_schema_data)
    assert_kind_of Committee::Drivers::HyperSchema::Schema, schema
    assert_equal @driver, schema.driver

    assert_kind_of Hash, schema.routes
    refute schema.routes.empty?
    assert(schema.routes.keys.all? { |m|
      ["DELETE", "GET", "PATCH", "POST", "PUT"].include?(m)
    })

    schema.routes.each do |(_, method_routes)|
      method_routes.each do |regex, link|
        assert_kind_of Regexp, regex
        assert_kind_of Committee::Drivers::HyperSchema::Link, link
      end
    end
  end

  it "defaults to not coercing form parameters" do
    assert_equal false, @driver.default_coerce_form_params
  end

  it "defaults to no path parameters" do
    assert_equal false, @driver.default_path_params
  end

  it "defaults to no query parameters" do
    assert_equal false, @driver.default_query_params
  end
end


# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers::OpenAPI2::Link do
  before do
    @link = Committee::Drivers::OpenAPI2::Link.new
    @link.enc_type = "application/x-www-form-urlencoded"
    @link.href = "/apps"
    @link.media_type = "application/json"
    @link.method = "GET"
    @link.status_success = 200
    @link.schema = { "title" => "input" }
    @link.target_schema = { "title" => "target" }
  end

  it "uses set #enc_type" do
    assert_equal "application/x-www-form-urlencoded", @link.enc_type
  end

  it "uses set #href" do
    assert_equal "/apps", @link.href
  end

  it "uses set #media_type" do
    assert_equal "application/json", @link.media_type
  end

  it "uses set #method" do
    assert_equal "GET", @link.method
  end

  it "proxies #rel" do
    e = assert_raises do
      @link.rel
    end
    assert_equal "Committee: rel not implemented for OpenAPI", e.message
  end

  it "uses set #schema" do
    assert_equal({ "title" => "input" }, @link.schema)
  end

  it "uses set #status_success" do
    assert_equal 200, @link.status_success
  end

  it "uses set #target_schema" do
    assert_equal({ "title" => "target" }, @link.target_schema)
  end
end


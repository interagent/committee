# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Options::Base do
  describe "#initialize" do
    it "accepts valid options with schema" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema)
      assert_equal hyper_schema, options.schema
    end

    it "accepts valid options with schema_path" do
      options = Committee::Middleware::Options::Base.new(schema_path: hyper_schema_schema_path)
      assert_equal hyper_schema_schema_path, options.schema_path
    end

    it "raises error when neither schema nor schema_path is provided" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::Base.new({})
      end
      assert_equal "Committee: need option `schema` or `schema_path`", e.message
    end

    it "raises error when error_class is not a Class" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::Base.new(schema: hyper_schema, error_class: "not a class")
      end
      assert_equal "error_class must be a Class", e.message
    end

    it "raises error when accept_request_filter is not callable" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::Base.new(schema: hyper_schema, accept_request_filter: "not callable")
      end
      assert_equal "accept_request_filter must respond to #call", e.message
    end

    it "uses default error_class when not provided" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema)
      assert_equal Committee::ValidationError, options.error_class
    end

    it "uses provided error_class" do
      custom_error = Class.new(StandardError)
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, error_class: custom_error)
      assert_equal custom_error, options.error_class
    end

    it "sets raise_error from :raise option" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, raise: true)
      assert_equal true, options.raise_error
    end

    it "sets prefix option" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, prefix: "/api/v1")
      assert_equal "/api/v1", options.prefix
    end

    it "sets accept_request_filter option" do
      filter = ->(request) { request.path.start_with?("/api") }
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, accept_request_filter: filter)
      assert_equal filter, options.accept_request_filter
    end

    it "sets strict_reference_validation option" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, strict_reference_validation: true)
      assert_equal true, options.strict_reference_validation
    end
  end

  describe "#[]" do
    it "provides Hash-like access" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, prefix: "/api")
      assert_equal "/api", options[:prefix]
    end
  end

  describe "#fetch" do
    it "returns value for existing key" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, prefix: "/api")
      assert_equal "/api", options.fetch(:prefix, nil)
    end

    it "returns default for missing key" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema)
      assert_equal "default", options.fetch(:nonexistent, "default")
    end
  end

  describe "#to_h" do
    it "returns Hash representation of options" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema, prefix: "/api")
      hash = options.to_h
      assert_kind_of Hash, hash
      assert_equal hyper_schema, hash[:schema]
      assert_equal "/api", hash[:prefix]
    end
  end

  describe ".from" do
    it "returns the same object if already an Options instance" do
      options = Committee::Middleware::Options::Base.new(schema: hyper_schema)
      assert_same options, Committee::Middleware::Options::Base.from(options)
    end

    it "creates new instance from Hash" do
      hash = { schema: hyper_schema, prefix: "/api" }
      options = Committee::Middleware::Options::Base.from(hash)
      assert_kind_of Committee::Middleware::Options::Base, options
      assert_equal "/api", options.prefix
    end

    it "raises error for invalid input" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::Base.from("invalid")
      end
      assert_match(/options must be a Hash or/, e.message)
    end
  end
end

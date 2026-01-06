# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Options::ResponseValidation do
  describe "#initialize" do
    it "inherits from Base" do
      assert Committee::Middleware::Options::ResponseValidation < Committee::Middleware::Options::Base
    end

    it "accepts valid options" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal hyper_schema, options.schema
    end

    it "sets strict option with default false" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal false, options.strict
    end

    it "sets strict option when provided" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, strict: true)
      assert_equal true, options.strict
    end

    it "sets ignore_error option with default false" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal false, options.ignore_error
    end

    it "sets ignore_error option when provided" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, ignore_error: true)
      assert_equal true, options.ignore_error
    end

    it "sets validate_success_only option with default true" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal true, options.validate_success_only
    end

    it "sets validate_success_only option when provided" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, validate_success_only: false)
      assert_equal false, options.validate_success_only
    end

    it "sets parse_response_by_content_type option with default true" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal true, options.parse_response_by_content_type
    end

    it "sets parse_response_by_content_type option when provided" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, parse_response_by_content_type: false)
      assert_equal false, options.parse_response_by_content_type
    end

    it "sets coerce_response_values option with default false" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal false, options.coerce_response_values
    end

    it "sets coerce_response_values option when provided" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, coerce_response_values: true)
      assert_equal true, options.coerce_response_values
    end

    it "sets error_handler option" do
      handler = ->(e, env) {}
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, error_handler: handler)
      assert_equal handler, options.error_handler
    end

    it "raises error when error_handler is not callable" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, error_handler: "not callable")
      end
      assert_equal "error_handler must respond to #call", e.message
    end

    it "sets streaming_content_parsers option with default empty hash" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_equal({}, options.streaming_content_parsers)
    end

    it "sets streaming_content_parsers option when provided" do
      parser = ->(body) { JSON.parse(body) }
      parsers = { "application/json" => parser }
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, streaming_content_parsers: parsers)
      assert_equal parsers, options.streaming_content_parsers
    end

    it "raises error when streaming_content_parsers is not a Hash" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, streaming_content_parsers: "not a hash")
      end
      assert_equal "streaming_content_parsers must be a Hash", e.message
    end
  end

  describe "#to_h" do
    it "includes ResponseValidation specific options" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema, strict: true, validate_success_only: false)
      hash = options.to_h
      assert_equal true, hash[:strict]
      assert_equal false, hash[:validate_success_only]
    end
  end

  describe ".from" do
    it "returns the same object if already an Options instance" do
      options = Committee::Middleware::Options::ResponseValidation.new(schema: hyper_schema)
      assert_same options, Committee::Middleware::Options::ResponseValidation.from(options)
    end

    it "creates new instance from Hash" do
      hash = { schema: hyper_schema, strict: true }
      options = Committee::Middleware::Options::ResponseValidation.from(hash)
      assert_kind_of Committee::Middleware::Options::ResponseValidation, options
      assert_equal true, options.strict
    end
  end
end

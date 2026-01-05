# frozen_string_literal: true

require "test_helper"

describe Committee::Middleware::Options::RequestValidation do
  describe "#initialize" do
    it "inherits from Base" do
      assert Committee::Middleware::Options::RequestValidation < Committee::Middleware::Options::Base
    end

    it "accepts valid options" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal hyper_schema, options.schema
    end

    it "sets strict option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.strict
    end

    it "sets strict option when provided" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, strict: true)
      assert_equal true, options.strict
    end

    it "sets ignore_error option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.ignore_error
    end

    it "sets ignore_error option when provided" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, ignore_error: true)
      assert_equal true, options.ignore_error
    end

    it "sets coerce_date_times option" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, coerce_date_times: true)
      assert_equal true, options.coerce_date_times
    end

    it "sets coerce_recursive option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.coerce_recursive
    end

    it "sets coerce_form_params option" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, coerce_form_params: true)
      assert_equal true, options.coerce_form_params
    end

    it "sets coerce_path_params option" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, coerce_path_params: true)
      assert_equal true, options.coerce_path_params
    end

    it "sets coerce_query_params option" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, coerce_query_params: true)
      assert_equal true, options.coerce_query_params
    end

    it "sets allow_form_params option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.allow_form_params
    end

    it "sets allow_query_params option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.allow_query_params
    end

    it "sets allow_get_body option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.allow_get_body
    end

    it "sets allow_non_get_query_params option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.allow_non_get_query_params
    end

    it "sets check_content_type option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.check_content_type
    end

    it "sets check_header option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.check_header
    end

    it "sets optimistic_json option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.optimistic_json
    end

    it "sets error_handler option" do
      handler = ->(e, env) {}
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, error_handler: handler)
      assert_equal handler, options.error_handler
    end

    it "raises error when error_handler is not callable" do
      e = assert_raises(ArgumentError) do
        Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, error_handler: "not callable")
      end
      assert_equal "error_handler must respond to #call", e.message
    end

    it "sets request_body_hash_key option with default" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal "committee.request_body_hash", options.request_body_hash_key
    end

    it "sets query_hash_key option with default" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal "committee.query_hash", options.query_hash_key
    end

    it "sets path_hash_key option with default" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal "committee.path_hash", options.path_hash_key
    end

    it "sets headers_key option with default" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal "committee.headers", options.headers_key
    end

    it "sets params_key option with default" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal "committee.params", options.params_key
    end

    it "sets allow_blank_structures option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.allow_blank_structures
    end

    it "sets allow_empty_date_and_datetime option with default false" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal false, options.allow_empty_date_and_datetime
    end

    it "sets parameter_overwrite_by_rails_rule option with default true" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_equal true, options.parameter_overwrite_by_rails_rule
    end

    it "sets deserialize_parameters option" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, deserialize_parameters: true)
      assert_equal true, options.deserialize_parameters
    end
  end

  describe "#to_h" do
    it "includes RequestValidation specific options" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema, strict: true, coerce_date_times: true)
      hash = options.to_h
      assert_equal true, hash[:strict]
      assert_equal true, hash[:coerce_date_times]
    end
  end

  describe ".from" do
    it "returns the same object if already an Options instance" do
      options = Committee::Middleware::Options::RequestValidation.new(schema: hyper_schema)
      assert_same options, Committee::Middleware::Options::RequestValidation.from(options)
    end

    it "creates new instance from Hash" do
      hash = { schema: hyper_schema, strict: true }
      options = Committee::Middleware::Options::RequestValidation.from(hash)
      assert_kind_of Committee::Middleware::Options::RequestValidation, options
      assert_equal true, options.strict
    end
  end
end

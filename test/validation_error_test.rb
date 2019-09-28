# frozen_string_literal: true

require "test_helper"

describe Committee::ValidationError do
  before do
    @error = Committee::ValidationError.new(400, :bad_request, "Error")
  end

  it "creates an error body with the id and message" do
    assert_equal @error.error_body, { id: :bad_request, message: "Error" }
  end

  it "creates a Rack response object to render" do
    body = { id: :bad_request, message: "Error" }

    response = [
      400,
      { "Content-Type" => "application/json" },
      [JSON.generate(body)]
    ]

    assert_equal @error.render, response
  end
end

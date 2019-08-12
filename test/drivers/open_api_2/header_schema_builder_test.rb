# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers::OpenAPI2::HeaderSchemaBuilder do
  it "returns schema data for header" do
    data = {
      "parameters" => [
        {
          "name" => "AUTH_TOKEN",
          "type" => "string",
          "in" => "header",
        }
      ]
    }
    schema = call(data)

    assert_equal ["string"], schema.properties["AUTH_TOKEN"].type
  end

  private

  def call(data)
    Committee::Drivers::OpenAPI2::HeaderSchemaBuilder.new(data).call
  end
end

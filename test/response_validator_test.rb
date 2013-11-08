require_relative "test_helper"

describe Rack::Committee::ResponseValidator do
  before do
    data = MultiJson.decode(File.read("./test/data/schema.json"))
    @type_schema = data["definitions"]["app"]
  end

  it "passes through a valid response" do
    Rack::Committee::ResponseValidator.new(ValidApp, @type_schema).call
  end

  it "detects missing keys in response" do
    data = ValidApp.dup
    data.delete("name")
    message = "Missing keys in response: name."
    assert_raises(Rack::Committee::InvalidResponse, message) do
      Rack::Committee::ResponseValidator.new(data, @type_schema).call
    end
  end

  it "detects extra keys in response" do
    data = ValidApp.dup
    data.merge!("tier" => "important")
    message = "Extra keys in response: tier."
    assert_raises(Rack::Committee::InvalidResponse, message) do
      Rack::Committee::ResponseValidator.new(data, @type_schema).call
    end
  end
end

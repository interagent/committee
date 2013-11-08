require_relative "test_helper"

describe Rack::Committee::ResponseValidator do
  before do
    @schema = Rack::Committee::Schema.new(File.read("./test/data/schema.json"))
  end

  it "passes through a valid response" do
    Rack::Committee::ResponseValidator.new(ValidApp, @schema, @schema["app"]).call
  end

  it "detects missing keys in response" do
    data = ValidApp.dup
    data.delete("name")
    message = "Missing keys in response: name."
    assert_raises(Rack::Committee::InvalidResponse, message) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
  end

  it "detects extra keys in response" do
    data = ValidApp.dup
    data.merge!("tier" => "important")
    message = "Extra keys in response: tier."
    assert_raises(Rack::Committee::InvalidResponse, message) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
  end

  it "detects mismatched types" do
    data = ValidApp.dup
    data.merge!("maintenance" => "not-bool")
    message = %{Invalid type at "maintenance": expected not-bool to be [boolean] (was: string).}
    assert_raises(Rack::Committee::InvalidResponse, message) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
  end
end

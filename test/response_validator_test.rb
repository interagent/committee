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
    e = assert_raises(Rack::Committee::InvalidResponse) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
    message = "Missing keys in response: name."
    assert_equal message, e.message
  end

  it "detects extra keys in response" do
    data = ValidApp.dup
    data.merge!("tier" => "important")
    e = assert_raises(Rack::Committee::InvalidResponse) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
    message = "Extra keys in response: tier."
    assert_equal message, e.message
  end

  it "detects mismatched types" do
    data = ValidApp.dup
    data.merge!("maintenance" => "not-bool")
    e = assert_raises(Rack::Committee::InvalidResponse) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
    message = %{Invalid type at "maintenance": expected not-bool to be ["boolean"] (was: string).}
    assert_equal message, e.message
  end

  it "detects bad formats" do
    data = ValidApp.dup
    data.merge!("id" => "123")
    e = assert_raises(Rack::Committee::InvalidResponse) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
    message = %{Invalid format at "id": expected "123" to be "uuid".}
    assert_equal message, e.message
  end

  it "detects bad patterns" do
    data = ValidApp.dup
    data.merge!("name" => "%@!")
    e = assert_raises(Rack::Committee::InvalidResponse) do
      Rack::Committee::ResponseValidator.new(data, @schema, @schema["app"]).call
    end
    message = %{Invalid pattern at "name": expected %@! to match "(?-mix:^[a-z][a-z0-9-]{3,30}$)".}
    assert_equal message, e.message
  end
end

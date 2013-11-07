require_relative "test_helper"

describe Rack::Committee::Schema do
  before do
    data = File.read("./test/schema.json")
    @schema = Rack::Committee::Schema.new(data)
  end

  it "is enumerable" do
    arr = @schema.to_a
    assert_equal "app", arr[0][0]
    assert arr[0][1].is_a?(Hash)
  end
end

require_relative "test_helper"

describe Committee::Schema do
  before do
    data = File.read("./test/data/schema.json")
    @schema = Committee::Schema.new(data)
  end

  it "is enumerable" do
    arr = @schema.to_a
    assert_equal "account", arr[0][0]
    assert arr[0][1].is_a?(Hash)
  end

  it "can lookup definitions" do
    expected = {
      "default"     => nil,
      "description" => "slug size in bytes of app",
      "example"     => 0,
      "readOnly"    => true,
      "type"        => ["number", "null"]
    }
    assert_equal expected, @schema.find("#/definitions/app/definitions/slug_size")
  end

  it "raises error on a non-existent definition" do
    assert_raises(Committee::ReferenceNotFound) do
      @schema.find("/schema/app#/definitions/bad_field")
    end
  end

  it "materializes regexes" do
    definition = @schema.find("#/definitions/app/definitions/git_url")
    assert definition["pattern"].is_a?(Regexp)
  end
end

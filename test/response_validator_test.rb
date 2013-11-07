require_relative "test_helper"

describe Rack::Committee::ResponseValidator do
  before do
    @schema = MultiJson.decode(File.read("./test/schema.json"))
  end

  it "passes through a valid response" do
    Rack::Committee::ResponseValidator.new(valid_data, @schema).call
  end

  it "detects missing keys in response" do
    data = valid_data
    data.delete("name")
    assert_raises(Rack::Committee::ResponseError) do
      Rack::Committee::ResponseValidator.new(data, @schema).call
    end
  end

  it "detects extra keys in response" do
    data = valid_data
    data.merge!("tier" => "important")
    assert_raises(Rack::Committee::ResponseError) do
      Rack::Committee::ResponseValidator.new(data, @schema).call
    end
  end

  def valid_data
    {
      "archived_at"                    => "",
      "buildpack_provided_description" => "",
      "created_at"                     => "",
      "id"                             => "",
      "git_url"                        => "",
      "maintenance"                    => "",
      "name"                           => "",
      "owner"                          => {
        "email"                        => "",
        "id"                           => "",
      },
      "region"                         => {
        "id"                           => "",
        "name"                         => "",
      },
      "released_at"                    => "",
      "repo_size"                      => "",
      "slug_size"                      => "",
      "stack"                          => {
        "id"                           => "",
        "name"                         => "",
      },
      "updated_at"                     => "",
      "web_url"                        => "",
    }
  end
end

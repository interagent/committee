require_relative "test_helper"

describe Committee::RequestValidator do
  before do
    @schema =
      JsonSchema.parse!(MultiJson.decode(File.read("./test/data/schema.json")))
    # POST /apps/:id
    @link = @link = @schema.properties["app"].links[0]
  end

  it "passes through a valid request" do
    params = {
      "name" => "heroku-api",
    }
    call(params)
  end

  it "detects a parameter of the wrong pattern" do
    params = {
      "name" => "%@!"
    }
    e = assert_raises(Committee::InvalidRequest) do
      call(params)
    end
    message = %{At "/schema/app": Expected string to match pattern "/^[a-z][a-z0-9-]{3,30}$/", value was: %@!.}
    assert_equal message, e.message
  end

  private

  def call(params)
    Committee::RequestValidator.new.call(@link, params)
  end
end

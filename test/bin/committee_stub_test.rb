require_relative "../test_helper"

describe Committee::Bin::CommitteeStub do
  before do
    @bin = Committee::Bin::CommitteeStub.new
  end

  it "produces a Rack app" do
    app = @bin.get_app(hyper_schema, {})
    assert_kind_of Rack::Builder, app
  end

  it "parses command line options" do
    options, parser = @bin.get_options_parser

    parser.parse!(["--help"])
    assert_equal true, options[:help]

    parser.parse!([
      "--driver", "open_api_2",
      "--tolerant", "true",
      "--port", "1234"
    ])
    assert_equal :open_api_2, options[:driver]
    assert_equal true, options[:tolerant]
    assert_equal "1234", options[:port]
  end
end

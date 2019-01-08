require_relative "test_helper"

describe Committee::Drivers do
  DRIVERS = [
    :hyper_schema,
    :open_api_2,
  ].freeze

  it "gets driver with .driver_from_name" do
    DRIVERS.each do |name|
      driver = Committee::Drivers.driver_from_name(name)
      assert_kind_of Committee::Drivers::Driver, driver
    end
  end

  it "raises an ArgumentError for an unknown driver with .driver_from_name" do
    e = assert_raises(ArgumentError) do
      Committee::Drivers.driver_from_name(:blueprint)
    end
    assert_equal %{Committee: unknown driver "blueprint".}, e.message
  end

  describe 'load_from_file(filepath)' do
    it 'load OpenAPI2' do
      s = Committee::Drivers.load_from_file(open_api_2_filepath)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'load Hyper-Schema' do
      s = Committee::Drivers.load_from_file(hyper_schema_filepath)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end
  end

  describe 'load_from_json(filepath)' do
    it 'load OpenAPI2' do
      s = Committee::Drivers.load_from_json(open_api_2_filepath)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'load Hyper-Schema' do
      s = Committee::Drivers.load_from_json(hyper_schema_filepath)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end
  end

  describe 'load_from_data(filepath)' do
    it 'load OpenAPI2' do
      s = Committee::Drivers.load_from_data(open_api_2_data)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'load Hyper-Schema' do
      s = Committee::Drivers.load_from_data(hyper_schema_data)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end
  end
end

describe Committee::Drivers::Driver do
  DRIVER_METHODS = {
    :default_coerce_form_params => [],
    :default_path_params        => [],
    :default_query_params       => [],
    :name                       => [],
    :parse                      => [nil],
    :schema_class               => [],
  }

  it "has a set of abstract methods" do
    driver = Committee::Drivers::Driver.new
    DRIVER_METHODS.each do |name, args|
      e = assert_raises do
        driver.send(name, *args)
      end
      assert_equal "needs implementation", e.message,
        "Incorrect error message while sending #{name}: #{e.message}"
    end
  end
end

describe Committee::Drivers::Schema do
  SCHEMA_METHODS = {
    :driver => [],
  }

  it "has a set of abstract methods" do
    schema = Committee::Drivers::Schema.new
    SCHEMA_METHODS.each do |name, args|
      e = assert_raises do
        schema.send(name, *args)
      end
      assert_equal "needs implementation", e.message,
        "Incorrect error message while sending #{name}: #{e.message}"
    end
  end
end

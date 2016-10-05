require_relative "test_helper"

describe Committee::Drivers do
  it "gets a driver with .driver_from_name" do
    driver = Committee::Drivers.driver_from_name(:hyper_schema)
    assert_kind_of Committee::Drivers::HyperSchema, driver
  end

  it "raises an ArgumentError for an unknown driver with .driver_from_name" do
    e = assert_raises(ArgumentError) do
      Committee::Drivers.driver_from_name(:blueprint)
    end
    assert_equal %{Committee: unknown driver "blueprint".}, e.message
  end
end

# frozen_string_literal: true

require "test_helper"

describe Committee::Drivers do
  DRIVERS = [
    :hyper_schema,
    :open_api_2,
    :open_api_3,
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

  describe 'load_from_file(schema_path)' do
    it 'loads OpenAPI2' do
      s = Committee::Drivers.load_from_file(open_api_2_schema_path)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'loads Hyper-Schema' do
      s = Committee::Drivers.load_from_file(hyper_schema_schema_path)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end

    it 'loads OpenAPI 3' do
      s = Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, s
    end

    it 'load OpenAPI 3 (patch version 3.0.1)' do
      s = Committee::Drivers.load_from_file(open_api_3_0_1_schema_path, parser_options:{strict_reference_validation: true})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, s
    end

    it 'fails to load OpenAPI 3.1' do
      e = assert_raises(Committee::OpenAPI3Unsupported) do
        Committee::Drivers.load_from_file(open_api_3_1_schema_path, parser_options:{strict_reference_validation: true})
      end
      assert_equal 'Committee does not support OpenAPI 3.1 yet', e.message
    end

    it 'fails to load OpenAPI 3 with invalid reference' do
      parser_options = { strict_reference_validation: true }
      assert_raises(OpenAPIParser::MissingReferenceError) do
        Committee::Drivers.load_from_file(open_api_3_invalid_reference_path, parser_options: parser_options)
      end
    end

    # This test can be removed when the test above (raising on invalid reference) becomes default behavior?
    it 'allows loading OpenAPI 3 with invalid reference as existing behavior' do
      s = Committee::Drivers.load_from_file(open_api_3_invalid_reference_path, parser_options:{strict_reference_validation: false})
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, s
    end

    it 'errors on an unsupported file extension' do
      e = assert_raises(StandardError) do
        Committee::Drivers.load_from_file('test.xml', parser_options:{strict_reference_validation: true})
      end
      assert_equal "Committee only supports the following file extensions: '.json', '.yaml', '.yml'", e.message
    end

    describe 'cache behavior' do
      describe 'when loading the same file' do
        it 'returns the same object when the options are identical' do
          assert_equal(
            Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true}).object_id,
            Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true}).object_id,
          )
        end

        it 'returns different objects if the options are different' do
          refute_equal(
            Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true}).object_id,
            Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: false}).object_id,
          )
        end

        it 'returns different objects if the file contents have changed' do
          object_id = Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true}).object_id
          original_file_contents = File.read(open_api_3_schema_path)
          File.write(open_api_3_schema_path, original_file_contents + "\n")
          refute_equal(
            Committee::Drivers.load_from_file(open_api_3_schema_path, parser_options:{strict_reference_validation: true}).object_id,
            object_id,
          )
          File.write(open_api_3_schema_path, original_file_contents)
        end
      end
    end
  end

  describe 'load_from_json(schema_path)' do
    it 'loads OpenAPI2' do
      s = Committee::Drivers.load_from_json(open_api_2_schema_path, parser_options:{strict_reference_validation: true})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'loads Hyper-Schema' do
      s = Committee::Drivers.load_from_json(hyper_schema_schema_path, parser_options:{strict_reference_validation: true})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end
  end

  describe 'load_from_yaml(schema_path)' do
    it 'loads OpenAPI3' do
      s = Committee::Drivers.load_from_yaml(open_api_3_schema_path, parser_options:{strict_reference_validation: true})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, s
    end
  end

  describe 'load_from_data(schema_path)' do
    it 'loads OpenAPI3' do
      s = Committee::Drivers.load_from_data(open_api_3_data, parser_options:{strict_reference_validation: false})
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI3::Schema, s
    end

    it 'loads OpenAPI2' do
      s = Committee::Drivers.load_from_data(open_api_2_data)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::OpenAPI2::Schema, s
    end

    it 'loads Hyper-Schema' do
      s = Committee::Drivers.load_from_data(hyper_schema_data)
      assert_kind_of Committee::Drivers::Schema, s
      assert_kind_of Committee::Drivers::HyperSchema::Schema, s
    end

    it 'fails to load OpenAPI 3.1' do
      e = assert_raises(Committee::OpenAPI3Unsupported) do
        Committee::Drivers.load_from_data(open_api_3_1_data)
      end
      assert_equal 'Committee does not support OpenAPI 3.1 yet', e.message
    end
  end
end

describe Committee::Drivers::Driver do
  DRIVER_METHODS = {
    default_allow_get_body: [],
    default_coerce_form_params: [],
    default_path_params: [],
    default_query_params: [],
    name: [],
    parse: [nil],
    schema_class: [],
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
    driver: [],
    build_router: [validator_option: nil, prefix: nil]
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

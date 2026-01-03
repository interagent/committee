# frozen_string_literal: true

require "test_helper"

describe Committee::SchemaValidator::OpenAPI3::ParameterDeserializer do
  before do
    @validator_option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
  end

  describe 'deserialize_parameters option' do
    it 'is enabled by default for OpenAPI 3' do
      option = Committee::SchemaValidator::Option.new({}, open_api_3_schema, :open_api_3)
      assert_equal true, option.deserialize_parameters
    end

    it 'can be disabled' do
      option = Committee::SchemaValidator::Option.new({ deserialize_parameters: false }, open_api_3_schema, :open_api_3)
      assert_equal false, option.deserialize_parameters
    end
  end

  describe 'parameter deserialization' do
    it 'deserializes form style object with explode=true' do
      raw_params = { 'role' => 'admin', 'status' => 'active' }
      param = create_param('filter', 'query', 'form', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
      assert_equal 'admin', result[:filter][:role]
    end

    it 'deserializes form style object with explode=false' do
      raw_params = { 'filter' => 'role,admin,status,active' }
      param = create_param('filter', 'query', 'form', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes form style array with explode=true' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'query', 'form', true, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes form style array with explode=false' do
      raw_params = { 'ids' => '1,2,3' }
      param = create_param('ids', 'query', 'form', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes deepObject style' do
      raw_params = { 'filter[role]' => 'admin', 'filter[status]' => 'active' }
      param = create_param('filter', 'query', 'deepObject', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes spaceDelimited style' do
      raw_params = { 'ids' => '1 2 3' }
      param = create_param('ids', 'query', 'spaceDelimited', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes pipeDelimited style' do
      raw_params = { 'ids' => '1|2|3' }
      param = create_param('ids', 'query', 'pipeDelimited', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes simple style array with explode=false for path params' do
      raw_params = { 'ids' => '1,2,3' }
      param = create_param('ids', 'path', 'simple', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes simple style array with explode=true for path params' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'path', 'simple', true, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes simple style object with explode=false for path params' do
      raw_params = { 'filter' => 'role,admin,status,active' }
      param = create_param('filter', 'path', 'simple', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes simple style object with explode=true for path params' do
      raw_params = { 'filter' => 'role=admin,status=active' }
      param = create_param('filter', 'path', 'simple', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes label style array with explode=false' do
      raw_params = { 'ids' => '.1,2,3' }
      param = create_param('ids', 'path', 'label', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes label style array with explode=true' do
      raw_params = { 'ids' => '.1.2.3' }
      param = create_param('ids', 'path', 'label', true, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes label style object with explode=false' do
      raw_params = { 'filter' => '.role,admin,status,active' }
      param = create_param('filter', 'path', 'label', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes label style object with explode=true' do
      raw_params = { 'filter' => '.role=admin.status=active' }
      param = create_param('filter', 'path', 'label', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes matrix style array with explode=false' do
      raw_params = { 'ids' => ';ids=1,2,3' }
      param = create_param('ids', 'path', 'matrix', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes matrix style array with explode=true' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'path', 'matrix', true, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes matrix style object with explode=false' do
      raw_params = { 'filter' => ';filter=role,admin,status,active' }
      param = create_param('filter', 'path', 'matrix', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes matrix style object with explode=true' do
      raw_params = { 'filter' => ';role=admin;status=active' }
      param = create_param('filter', 'path', 'matrix', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'deserializes matrix style primitive' do
      raw_params = { 'id' => ';id=5' }
      param = create_param('id', 'path', 'matrix', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '5' }, result)
    end

    it 'deserializes headers with simple style' do
      raw_params = { 'X-Filter' => 'role,admin,status,active' }
      param = create_param('X-Filter', 'header', 'simple', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_headers(raw_params)

      assert_equal({ 'X-Filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'handles empty params gracefully' do
      raw_params = {}
      param = create_param('filter', 'query', 'form', true, 'object', { 'role' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({}, result)
    end

    it 'handles nil param value' do
      raw_params = { 'filter' => nil }
      param = create_param('filter', 'query', 'form', false, 'object', { 'role' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => nil }, result)
    end

    it 'preserves unknown parameters' do
      raw_params = { 'role' => 'admin', 'unknown' => 'value' }
      param = create_param('filter', 'query', 'form', true, 'object', { 'role' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal 'admin', result[:filter][:role]
      assert_equal 'value', result[:unknown]
    end

    it 'handles empty object with form style explode=true' do
      raw_params = {}
      param = create_param('filter', 'query', 'form', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({}, result)
    end

    it 'returns indifferent hashes' do
      raw_params = { 'role' => 'admin' }
      param = create_param('filter', 'query', 'form', true, 'object', { 'role' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'role' => 'admin' }, result['filter'])
      assert_equal 'admin', result['filter']['role']
      assert_equal({ 'role' => 'admin' }, result[:filter])
      assert_equal 'admin', result[:filter][:role]
    end

    it 'handles primitive values with form style' do
      raw_params = { 'id' => '123' }
      param = create_param('id', 'query', 'form', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles primitive values with simple style' do
      raw_params = { 'id' => '123' }
      param = create_param('id', 'path', 'simple', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles unsupported style gracefully' do
      raw_params = { 'id' => '123' }
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('id', 'query', 'unsupported', false, create_schema('string', nil), false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles form array when value is already array' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'query', 'form', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'deserializes label style primitive value' do
      raw_params = { 'id' => '.123' }
      param = create_param('id', 'path', 'label', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles label style without leading dot' do
      raw_params = { 'id' => '123' }
      param = create_param('id', 'path', 'label', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles matrix style with missing prefix' do
      raw_params = { 'ids' => 'invalid' }
      param = create_param('ids', 'path', 'matrix', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => [] }, result)
    end

    it 'handles matrix style object with missing prefix' do
      raw_params = { 'filter' => 'invalid' }
      param = create_param('filter', 'path', 'matrix', false, 'object', { 'role' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => {} }, result)
    end

    it 'handles matrix style primitive without prefix' do
      raw_params = { 'id' => 'invalid' }
      param = create_param('id', 'path', 'matrix', false, 'string', nil)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => 'invalid' }, result)
    end

    it 'handles space delimited when value is already array' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'query', 'spaceDelimited', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'handles pipe delimited when value is already array' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'query', 'pipeDelimited', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'handles simple array when value is already array' do
      raw_params = { 'ids' => ['1', '2', '3'] }
      param = create_param('ids', 'path', 'simple', false, 'array', 'integer')
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'ids' => ['1', '2', '3'] }, result)
    end

    it 'handles comma-separated object with odd number of elements' do
      raw_params = { 'filter' => 'role,admin,status' }
      param = create_param('filter', 'query', 'form', false, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin' } }, result)
    end

    it 'handles matrix object exploded with malformed pairs' do
      raw_params = { 'filter' => ';role=admin;invalid;status=active' }
      param = create_param('filter', 'path', 'matrix', true, 'object', { 'role' => 'string', 'status' => 'string' })
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'filter' => { 'role' => 'admin', 'status' => 'active' } }, result)
    end

    it 'handles parameter without schema in simple style' do
      raw_params = { 'id' => '123' }
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('id', 'path', 'simple', false, nil, false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles parameter without schema in label style' do
      raw_params = { 'id' => '.123' }
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('id', 'path', 'label', false, nil, false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles parameter without schema in matrix style' do
      raw_params = { 'id' => ';id=123' }
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('id', 'path', 'matrix', false, nil, false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_path_params(raw_params)

      assert_equal({ 'id' => ';id=123' }, result)
    end

    it 'handles parameter without schema in form style' do
      raw_params = { 'id' => '123' }
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('id', 'query', 'form', false, nil, false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'id' => '123' }, result)
    end

    it 'handles form explode with symbol property keys' do
      raw_params = { 'role' => 'admin', 'status' => 'active' }
      # Create schema with symbol keys for properties
      schema = Struct.new(:type, :properties, :items).new('object', { role: Struct.new(:type).new('string'), status: Struct.new(:type).new('string') }, nil)
      param = Struct.new(:name, :in, :style, :explode, :schema, :required).new('filter', 'query', 'form', true, schema, false)
      deserializer = create_deserializer([param])
      result = deserializer.deserialize_query_params(raw_params)

      assert_equal({ 'filter' => { role: 'admin', status: 'active' } }, result)
    end
  end

  private

  def create_deserializer(params)
    operation = Struct.new(:operation_object).new(Struct.new(:parameters).new(params))
    Committee::SchemaValidator::OpenAPI3::ParameterDeserializer.new(operation)
  end

  def create_param(name, location, style, explode, type, properties_or_items)
    Struct.new(:name, :in, :style, :explode, :schema, :required).new(name, location, style, explode, create_schema(type, properties_or_items), false)
  end

  def create_schema(type, properties_or_items)
    if type == 'object'
      props = properties_or_items.transform_values { |v| Struct.new(:type).new(v) }
      Struct.new(:type, :properties, :items).new(type, props, nil)
    elsif type == 'array'
      Struct.new(:type, :properties, :items).new(type, nil, Struct.new(:type).new(properties_or_items))
    else
      Struct.new(:type, :properties, :items).new(type, nil, nil)
    end
  end
end

require_relative '../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator do
  let(:root) { OpenAPIParser::Schemas::OpenAPI.new(normal_schema) }

  describe 'validate' do
    subject { request_operation.validate_request_body('application/json', params) }

    let(:content_type) { 'application/json' }
    let(:http_method) { :post }
    let(:request_path) { '/validate' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { {} }

    it 'correct' do
      params = [
          ['string', 'str'],
          ['integer', 1],
          ['boolean', true],
          ['boolean', false],
          ['number', 0.1],
      ].to_h

      ret = request_operation.validate_request_body(content_type, params)
      expect(ret).to eq nil
    end

    it 'correct object data' do
      params = {
          "object_1" =>
              {
                  "string_1" => nil,
                  "integer_1" => nil,
                  "boolean_1" => nil,
                  "number_1" => nil
              }
      }

      ret = request_operation.validate_request_body(content_type, params)
      expect(ret).to eq nil
    end

    it 'invalid params' do
      invalids = [
          ['string', 1],
          ['string', true],
          ['string', false],
          ['integer', '1'],
          ['integer', 0.1],
          ['integer', true],
          ['integer', false],
          ['boolean', 1],
          ['boolean', 'true'],
          ['boolean', 'false'],
          ['boolean', '0.1'],
          ['number', '0.1'],
          ['number', true],
          ['number', false],
          ['array', false],
          ['array', 1],
          ['array', true],
          ['array', '1'],
      ]

      invalids.each do |key, value|
        params = {"#{key}" => value}

        expect{ request_operation.validate_request_body(content_type, params) }.to raise_error do |e|
          expect(e.is_a?(OpenAPIParser::ValidateError)).to eq true
          expect(e.message.start_with?("#{value} class is #{value.class}")).to eq true
        end
      end
    end

    it 'required params' do
      object_2 = {
          "string_2" => "str",
          "integer_2" => 1,
          "boolean_2" => true,
          "number_2" => 0.1
      }

      object_2.keys.each do |key|
        deleted_object = object_2.reject{|k, _v| k == key}
        params = {"object_2" => deleted_object}
        expect{ request_operation.validate_request_body(content_type, params) }.to raise_error do |e|
          expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
          expect(e.message.start_with?("required parameters #{key} not exist")).to eq true
        end
      end

      params = {"object_2" => {}}
      expect{ request_operation.validate_request_body(content_type, params)  }.to raise_error do |e|
        expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
        expect(e.message.start_with?("required parameters #{object_2.keys.join(",")} not exist")).to eq true
      end
    end

    context 'nested required params' do
      subject { request_operation.validate_request_body(content_type, {"required_object" => required_object}) }

      let(:required_object_base) do
        JSON.load(
            {
                need_object: {
                    string: 'abc'
                },
                no_need_object: {
                    integer: 1
                }
            }.to_json
        )
      end
      let(:required_object) { required_object_base }

      context 'normal' do
        it { expect(subject).to eq nil }
      end

      context 'no need object delete' do
        let(:required_object) do
          required_object_base.delete "no_need_object"
          required_object_base
        end
        it { expect(subject).to eq nil }
      end

      context 'delete required params' do
        let(:required_object) do
          required_object_base['need_object'].delete "string"
          required_object_base
        end
        it do
          expect{ subject }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
            expect(e.message.start_with?("required parameters string not exist")).to eq true
          end
        end
      end

      context 'required object not exist' do
        let(:required_object) do
          required_object_base.delete 'need_object'
          required_object_base
        end
        it do
          expect{ subject }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
            expect(e.message.start_with?("required parameters need_object not exist")).to eq true
          end
        end
      end
    end


    describe 'array' do
      subject { request_operation.validate_request_body(content_type, {"array" => array_data}) }

      context 'correct' do
        let(:array_data) { [1] }
        it { expect(subject).to eq nil }
      end

      context 'other value include' do
        let(:array_data) { [1, 1.1] }

        it do
          expect{ subject }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::ValidateError)).to eq true
            expect(e.message.start_with?("1.1 class is Float")).to eq true
          end
        end
      end

      context 'empty' do
        let(:array_data) { [] }
        it { expect(subject).to eq nil }
      end

      context 'nil' do
        let(:array_data) { [nil] }

        it do
          expect{ subject }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotNullError)).to eq true
            expect(e.message.include?("don't allow null")).to eq true
          end
        end
      end

      context 'anyOf' do
        it do
          expect(request_operation.validate_request_body(content_type, {"any_of" => ['test', true]})).to eq nil
        end

        it 'invalid' do
          expect{ request_operation.validate_request_body(content_type, {"any_of" => [1]}) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotAnyOf)).to eq true
            expect(e.message.start_with?("1 isn't any of")).to eq true
          end
        end
      end
    end

    describe 'enum' do
      context 'enum string' do
        it 'include enum' do
          ['a', 'b'].each do |str|
            expect(request_operation.validate_request_body(content_type, {"enum_string" => str})).to eq nil
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_string" => 'x'}) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("x isn't include enum")).to eq true
          end
        end
      end

      context 'enum integer' do
        it 'include enum' do
          [1, 2].each do |str|
            expect(request_operation.validate_request_body(content_type, {"enum_integer" => str})).to eq nil
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_integer" => 3}) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("3 isn't include enum")).to eq true
          end
        end
      end

      context 'enum number' do
        it 'include enum' do
          [1.0, 2.1].each do |str|
            expect(request_operation.validate_request_body(content_type, {"enum_number" => str})).to eq nil
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_number" => 1.1}) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("1.1 isn't include enum")).to eq true
          end
        end
      end
    end

    it 'unknown param' do
      expect(request_operation.validate_request_body(content_type, {"unknown" => 1})).to eq nil
    end

=begin
      describe 'support get method' do
        before do
          @method = "get"
        end

        it 'correct' do
          operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2]})
          operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => 1})

          assert true
        end

        it 'not exist required' do
          e = assert_raises(Committee::InvalidRequest) {
            operation_object.validate_request_params({"query_integer_list" => [1, 2]})
          }

          assert e.message.start_with?("required parameters query_string not exist")

          e = assert_raises(Committee::InvalidRequest) {
            operation_object.validate_request_params({"query_string" => "query"})
          }

          assert e.message.start_with?("required parameters query_integer_list not exist")
        end

        it 'invalid type' do
          e = assert_raises(Committee::InvalidRequest) {
            operation_object.validate_request_params({"query_string" => 1, "query_integer_list" => [1, 2], "optional_integer" => 1})
          }

          assert e.message.start_with?("invalid parameter type query_string 1 Integer string")

          e = assert_raises(Committee::InvalidRequest) {
            operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => ['1', 2], "optional_integer" => 1})
          }

          assert e.message.start_with?("invalid parameter type query_integer_list 1 String integer")

          e = assert_raises(Committee::InvalidRequest) {
            operation_object.validate_request_params({"query_string" => "query", "query_integer_list" => [1, 2], "optional_integer" => '1'})
          }

          assert e.message.start_with?("invalid parameter type optional_integer 1 String integer")
        end
      end
=end
  end
end

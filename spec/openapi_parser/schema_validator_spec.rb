require_relative '../spec_helper'

RSpec.describe OpenAPIParser::SchemaValidator do
  let(:root) { OpenAPIParser.parse(normal_schema, config) }
  let(:config) { {} }

  describe 'validate' do
    subject { request_operation.validate_request_body('application/json', params, options) }

    let(:options) { OpenAPIParser::SchemaValidator::Options.new(coerce_value: false)}

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

      ret = request_operation.validate_request_body(content_type, params, options)
      expect(ret).to eq({"boolean"=>false, "integer"=>1, "number"=>0.1, "string"=>"str"})
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

      ret = request_operation.validate_request_body(content_type, params, options)
      expect(ret).to eq({"object_1"=>{"boolean_1"=>nil, "integer_1"=>nil, "number_1"=>nil, "string_1"=>nil}})
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

        expect{ request_operation.validate_request_body(content_type, params, options) }.to raise_error do |e|
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
        expect{ request_operation.validate_request_body(content_type, params, options) }.to raise_error do |e|
          expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
          expect(e.message.start_with?("required parameters #{key} not exist")).to eq true
        end
      end

      params = {"object_2" => {}}
      expect{ request_operation.validate_request_body(content_type, params, options)  }.to raise_error do |e|
        expect(e.is_a?(OpenAPIParser::NotExistRequiredKey)).to eq true
        expect(e.message.start_with?("required parameters #{object_2.keys.join(",")} not exist")).to eq true
      end
    end

    context 'nested required params' do
      subject { request_operation.validate_request_body(content_type, {"required_object" => required_object}, options) }

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
        it { expect(subject).to eq({"required_object"=>{"need_object"=>{"string"=>"abc"}, "no_need_object"=>{"integer"=>1}}}) }
      end

      context 'no need object delete' do
        let(:required_object) do
          required_object_base.delete "no_need_object"
          required_object_base
        end
        it { expect(subject).to eq ({"required_object"=>{"need_object"=>{"string"=>"abc"}}}) }
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
      subject { request_operation.validate_request_body(content_type, {"array" => array_data}, options) }

      context 'correct' do
        let(:array_data) { [1] }
        it { expect(subject).to eq ({"array" => [1]}) }
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
        it { expect(subject).to eq({"array" => []}) }
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
          expect(request_operation.validate_request_body(content_type, {"any_of" => ['test', true]}, options)).
              to eq({"any_of" => ['test', true]})
        end

        it 'invalid' do
          expect{ request_operation.validate_request_body(content_type, {"any_of" => [1]}, options) }.to raise_error do |e|
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
            expect(request_operation.validate_request_body(content_type, {"enum_string" => str}, options)).
                to eq({"enum_string" => str})
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_string" => 'x'}, options) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("x isn't include enum")).to eq true
          end
        end
      end

      context 'enum integer' do
        it 'include enum' do
          [1, 2].each do |str|
            expect(request_operation.validate_request_body(content_type, {"enum_integer" => str}, options)).
                to eq({"enum_integer" => str})
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_integer" => 3}, options) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("3 isn't include enum")).to eq true
          end
        end
      end

      context 'enum number' do
        it 'include enum' do
          [1.0, 2.1].each do |str|
            expect(request_operation.validate_request_body(content_type, {"enum_number" => str}, options)).
                to eq({"enum_number" => str})
          end
        end

        it 'not include enum' do
          expect{ request_operation.validate_request_body(content_type, {"enum_number" => 1.1}, options) }.to raise_error do |e|
            expect(e.is_a?(OpenAPIParser::NotEnumInclude)).to eq true
            expect(e.message.start_with?("1.1 isn't include enum")).to eq true
          end
        end
      end
    end

    it 'unknown param' do
      expect(request_operation.validate_request_body(content_type, {"unknown" => 1}, options)).to eq({"unknown"=>1})
    end
  end

  describe 'coerce' do
    subject { request_operation.validate_request_parameter(params) }

    let(:config) { {coerce_value: true} }

    let(:content_type) { 'application/json' }
    let(:http_method) { :get }
    let(:request_path) { '/string_params_coercer' }
    let(:request_operation) { root.request_operation(http_method, request_path) }
    let(:params) { { "#{key}" => "#{value}"} }

    let(:nested_array) do
        [
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => "1",
                "nested_coercer_object" => {
                    "update_time" => "2016-04-01T16:00:00.000+09:00",
                    "threshold" => "1.5"
                },
                "nested_no_coercer_object" => {
                    "per_page" => "1",
                    "threshold" => "1.5"
                },
                "nested_coercer_array" => [
                    {
                        "update_time" => "2016-04-01T16:00:00.000+09:00",
                        "threshold" => "1.5"
                    }
                ],
                "nested_no_coercer_array" => [
                    {
                        "per_page" => "1",
                        "threshold" => "1.5"
                    }
                ]
            },
            {
                "update_time" => "2016-04-01T16:00:00.000+09:00",
                "per_page" => "1",
                "threshold" => "1.5"
            },
            {
                "threshold" => "1.5",
                "per_page" => "1"
            }
        ]
    end

    context 'string' do
      context "doesn't coerce params not in the schema" do
        let(:params) { { "owner" => "admin"} }

        it do
          expect(subject).to eq({ "owner" => "admin"})
          expect(params["owner"]).to eq "admin"
        end
      end

      context "skips values for string param" do
        let(:params) { { "#{key}" => "#{value}"} }
        let(:key) { "string_1" }
        let(:value) { "foo" }

        it do
          expect(subject).to eq({ "#{key}" => "#{value}"})
          expect(params[key]).to eq value
        end
      end
    end

    context 'boolean' do
      let(:key) { "boolean_1" }

      context "coerces valid values for boolean param" do
        using RSpec::Parameterized::TableSyntax

        where( :before_value, :result_value) do
          "true" | true
          "false" | false
          "1" | true
          "0" | false
        end

        with_them do
          let(:value) { before_value}
          it do
            expect(subject).to eq({"#{key}" => result_value})
            expect(params[key]).to eq result_value
          end
        end
      end

      context "skips invalid values for boolean param" do
        let(:value) { "foo" }

        it do
          expect{ subject }.to raise_error(OpenAPIParser::ValidateError)
        end
      end
    end

    context 'integer' do
      let(:key) { "integer_1" }

      context "coerces valid values for integer param" do
        let(:value) { "3" }
        let(:params) { { "#{key}" => "#{value}"} }

        it do
          expect(subject).to eq({"#{key}" => 3})
          expect(params[key]).to eq 3
        end
      end

      context "skips invalid values for integer param" do
        using RSpec::Parameterized::TableSyntax

        where( :before_value) { ["3.5" ,"false",""] }

        with_them do
          let(:value) { before_value}
          it do
            expect{ subject }.to raise_error(OpenAPIParser::ValidateError)
          end
        end
      end
    end

    context 'number' do
      let(:key) { "number_1" }

      context "coerces valid values for number param" do
        using RSpec::Parameterized::TableSyntax

        where( :before_value, :result_value) do
          "3" | 3.0
          "3.5" | 3.5
        end

        with_them do
          let(:value) { before_value}
          it do
            expect(subject).to eq({"#{key}" => result_value})
            expect(params[key]).to eq result_value
          end
        end
      end

      context "invalid values" do
        let(:value) { "false" }

        it do
          expect{ subject }.to raise_error(OpenAPIParser::ValidateError)
        end
      end
    end

    describe "array" do
      context "normal array" do
        let(:params) do
          {
              "normal_array" => [
                  "1"
              ]
          }
        end

        it do
          expect(subject["normal_array"][0]).to eq 1
          expect(params["normal_array"][0]).to eq 1
        end
      end

      xcontext 'nested_array' do
        let(:params) do
          { "nested_array" => nested_array }
        end
        let(:coerce_date_times) { false }

        it do
          subject

          nested_array = params["nested_array"]
          first_data = nested_array[0]
          expect(first_data["update_time"].class).to eq String
          expect(first_data["per_page"].class).to eq Integer

          second_data = nested_array[1]
          expect(second_data["update_time"].class).to eq String
          expect(second_data["per_page"].class).to eq Integer
          expect(second_data["threshold"].class).to eq Float

          third_data = nested_array[2]
          expect(third_data["per_page"].class).to eq Integer
          expect(third_data["threshold"].class).to eq Float

          expect(first_data["nested_coercer_object"]["update_time"]).to eq String
          expect(first_data["nested_coercer_object"]["threshold"]).to eq Float

          expect(first_data["nested_no_coercer_object"]["per_page"]).to eq String
          expect(first_data["nested_no_coercer_object"]["threshold"]).to eq String

          expect(first_data["nested_coercer_array"].first["update_time"]).to eq String
          expect(first_data["nested_coercer_array"].first["threshold"]).to eq Float

          expect(first_data["nested_no_coercer_array"].first["per_page"]).to eq String
          expect(first_data["nested_no_coercer_array"].first["threshold"]).to eq String
        end
      end
    end

    context 'datetime_coercer' do
      let(:config) { {coerce_value: true, datetime_coerce_class: DateTime} }

       context 'correct datetime' do
         let(:params) { { "datetime_string" => "2016-04-01T16:00:00.000+09:00"} }

         it do
           expect(subject["datetime_string"].class).to eq DateTime
           expect(params["datetime_string"].class).to eq DateTime
         end
       end

       context 'correct Time' do
         let(:params) { { "datetime_string" => "2016-04-01T16:00:00.000+09:00"} }
         let(:config) { {coerce_value: true, datetime_coerce_class: Time} }

         it do
           expect(subject["datetime_string"].class).to eq Time
           expect(params["datetime_string"].class).to eq Time
         end
       end

       context 'invalid datetime not parsed' do
         let(:params) { { "datetime_string" => "honoka"} }

         it { expect(subject["datetime_string"]).to eq 'honoka' }
       end

       context "don't change object type" do
         class HashLikeObject < Hash; end

         let(:params) do
           h = HashLikeObject.new
           h["datetime_string"] = "2016-04-01T16:00:00.000+09:00"
           h
         end

         it do
           expect(subject["datetime_string"].class).to eq DateTime
           expect(subject.class).to eq HashLikeObject
         end
       end

      xcontext "nested array" do
        let(:params) { { "nested_array" => nested_array } }
        it do
          subject

          nested_array = params["nested_array"]
          first_data = nested_array[0]
          expect(first_data["update_time"].class).to eq DateTime

          second_data = nested_array[1]
          expect(second_data["update_time"].class).to eq DateTime

          expect(first_data["nested_coercer_object"]["update_time"].class).to eq DateTime
          expect(first_data["nested_coercer_array"]["update_time"].class).to eq DateTime
        end
      end
    end
  end
end

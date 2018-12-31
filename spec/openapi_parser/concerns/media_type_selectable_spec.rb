require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::MediaTypeSelectable do
  let(:root) { OpenAPIParser.parse(petstore_schema, {}) }

  describe '#select_media_type(content_type, content)' do
    subject { media_type_selectable.select_media_type(content_type) }

    context '*/* exist' do
      let(:paths) { root.paths }
      let(:path_item) { paths.path['/pets'] }
      let(:operation) { path_item.get }
      let(:responses) { operation.responses }
      let(:media_type_selectable) { responses.response['200'] }

      context 'application/json' do
        let(:content_type) { 'application/json' }
        it { expect(subject.object_reference.include?('application~1json')).to eq true }
      end

      context 'application/unknown' do
        let(:content_type) { 'application/unknown' }
        it { expect(subject.object_reference.include?('application~1unknown')).to eq true }
      end

      context 'application/abc' do
        let(:content_type) { 'application/abc' }
        it { expect(subject.object_reference.include?('application~1*')).to eq true }
      end

      context 'not mach' do
        let(:content_type) { 'xyz/abc' }
        it { expect(subject.object_reference.include?('*~1*')).to eq true }
      end
    end

    context '*/* not exist' do
      let(:paths) { root.paths }
      let(:path_item) { paths.path['/pets'] }
      let(:operation) { path_item.post }
      let(:request_body) { operation.request_body }

      let(:media_type_selectable) { request_body }

      let(:content_type) { 'application/unknown' }

      it 'return nil' do
        expect(subject).to eq nil
      end
    end
  end
end

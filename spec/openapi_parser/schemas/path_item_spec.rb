require_relative '../../spec_helper'

RSpec.describe OpenAPIParser::Schemas::PathItem do
  let(:root) { OpenAPIParser.parse(normal_schema, {}) }

  describe "#init" do
    subject{ path_item }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to be nil
      expect(subject.object_reference).to eq '#/paths/~1characters'
      expect(subject.summary).to eq 'summary_text'
      expect(subject.description).to eq 'desc'
      expect(subject.root.object_id).to be root.object_id
    end
  end

  describe "#parameters" do
    subject{ path_item }

    let(:root) { OpenAPIParser.parse(petstore_schema, {}) }
    let(:paths) { root.paths }
    let(:path_item) { paths.path['/animals/{id}'] }

    it do
      expect(subject.parameters.size).to eq 1
      expect(subject.parameters.first.name).to eq 'id'
    end
  end

  describe "#get" do
    subject { path_item.get }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to eq nil
      expect(subject.is_a?(OpenAPIParser::Schemas::Operation)).to eq true
      expect(subject.object_reference).to eq '#/paths/~1characters/get'
    end
  end

  describe "#post" do
    subject { path_item.post }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).not_to eq nil
      expect(subject.is_a?(OpenAPIParser::Schemas::Operation)).to eq true
    end
  end

  describe "#head" do
    subject { path_item.head }

    let(:paths) { root.paths }
    let(:path_item) { paths.path['/characters'] }

    it do
      expect(subject).to eq nil # head is null
    end
  end
end

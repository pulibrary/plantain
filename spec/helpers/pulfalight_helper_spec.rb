# frozen_string_literal: true
require "rails_helper"

describe PulfalightHelper, type: :helper do
  describe "#current_year" do
    it "returns the current year" do
      expect(helper.current_year).to eq DateTime.current.year
    end
  end

  context "with a component document" do
    let(:indexer_settings) do
      {
        repository: "publicpolicy"
      }
    end
    let(:indexer) do
      Traject::Indexer::NokogiriIndexer.new(indexer_settings).tap do |i|
        i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
      end
    end
    let(:fixture_file) do
      File.read(fixture_path)
    end
    let(:nokogiri_reader) do
      Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, indexer.settings)
    end
    let(:xml_documents) do
      nokogiri_reader.to_a
    end
    let(:xml_document) do
      xml_documents.first
    end
    let(:collection_values) do
      indexer.map_record(xml_document)
    end
    let(:component_values) do
      components = collection_values["components"]
      components.first
    end
    let(:component_document) do
      SolrDocument.new(component_values)
    end
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
    end

    before do
      allow(helper).to receive(:document).and_return(component_document)
    end

    describe "#html_presenter" do
      it "accesses the presenter Class used for generating HTML markup" do
        expect(helper.html_presenter).to be_a(ComponentHtmlPresenter)
        expect(helper.html_presenter.collection_notes).to include("<p>Consists of two groups of material collected by Ferree: 1) copies of government reports,")
        expect(helper.html_presenter.collection_notes).to include("</p>")
      end
    end

    describe "#component_notes_formatter" do
      it "generates the HTML markup" do
        expect(helper.component_notes_formatter).to include("<p>Consists of two groups of material collected by Ferree: 1) copies of government reports,")
        expect(helper.component_notes_formatter).to include("</p>")
      end
    end
  end

  describe "#available_request_types" do
    it "retrieves the types of requests configured for collections and components" do
      expect(helper.available_request_types).to include(:aeon_external_request_endpoint)
    end
  end
end
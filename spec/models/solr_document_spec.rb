# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arclight::SolrDocument do
  subject(:document) { SolrDocument.new(values) }

  let(:values) { {} }
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
  let(:records) do
    nokogiri_reader.to_a
  end
  let(:record) do
    records.first
  end

  describe "custom accessors" do
    it { expect(document).to respond_to(:parent_ids) }
    it { expect(document).to respond_to(:parent_labels) }
    it { expect(document).to respond_to(:eadid) }
  end

  describe "#collection?" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end

    it "determines whether or not a document is an EAD collection" do
      expect(document.collection?).to be true
    end
  end

  context "when the collection contains one or more member components" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
    end
    let(:collection_values) do
      indexer.map_record(record)
    end
    let(:values) do
      collection_values["components"].first
    end

    describe "#component?" do
      it "determines whether or not a document is an EAD collection" do
        expect(document.component?).to be true
      end
    end

    describe "#html_presenter_class" do
      it "provides the Class used as a presenter for the SolrDocument" do
        expect(document.html_presenter_class).to eq(ComponentHtmlPresenter)
      end
    end
  end

  context "when the collection contains an encoded physical location" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end

    describe "#physical_locations" do
      it "accesses the encoded physical locations" do
        expect(document.physical_locations).not_to be_empty
        expect(document.physical_locations).to include("mudd")
      end
    end

    describe "#last_physical_location" do
      it "accesses the last encoded physical location" do
        expect(document.last_physical_location).to eq("mudd")
      end
    end
  end

  describe "#to_json" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end
    let(:document) { SolrDocument.new(values) }
    let(:serialized) { document.to_json }
    it "builds the JSON for the Document" do
      expect(serialized).to be_a(String)
      expect(serialized).not_to be_empty

      built = JSON.parse(serialized)
      expect(built).to include("id" => "WC064")
      expect(built).to include("unittitle")
      expect(built["unittitle"]).not_to be_empty
      expect(built["unittitle"].first).to include("Princeton University Library Collection of Western Americana")
      expect(built).to include("has_digital_content")
      expect(built["has_digital_content"]).to be true

      expect(built).to include("components")
      expect(built["components"]).not_to be_empty
      first_child = built["components"].first
      expect(first_child).to include("id" => "WC064_c1")
      expect(first_child).to include("has_digital_content" => true)
    end
  end

  describe "#collection?" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end
    let(:document) { SolrDocument.new(values) }

    it "determines whether or not a document is an EAD collection" do
      expect(document.collection?).to be true
    end
  end

  describe "#aeon_request" do
    it "returns an object with all the necessary attributes" do
      fixture = Rails.root.join("spec", "fixtures", "C1588.json")
      fixture = JSON.parse(fixture.read)
      component = fixture["components"].first["components"].first["components"].first
      document = SolrDocument.new(component)

      request = document.aeon_request
      expect(request.attributes[:callnumber]).to eq "aspace_C1588_c3"
      expect(request.attributes[:title]).to eq "Diary"
      expect(request.attributes[:containers]).to eq "Box B-001180, Folder 1"
      expect(request.form_attributes[:AeonForm]).to eq "EADRequest"
      expect(request.form_attributes[:RequestType]).to eq "Loan"
      expect(request.form_attributes[:DocumentType]).to eq "Manuscript"
      expect(request.form_attributes[:Site]).to eq "RBSC"
      expect(request.form_attributes[:Location]).to eq "mss"
      expect(request.form_attributes[:ItemTitle]).to eq "Diary"
      expect(request.form_attributes[:GroupingIdentifier]).to eq "ItemVolume"
      expect(request.form_attributes[:GroupingOption_ReferenceNumber]).to eq "Concatenate"
      expect(request.form_attributes[:GroupingOption_ItemNumber]).to eq "Concatenate"
      expect(request.form_attributes[:GroupingOption_ItemDate]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_CallNumber]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemVolume]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemInfo1]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_Location]).to eq "FirstValue"

      # The following attributes are copied from
      # https://findingaids.princeton.edu/collections/C1588/c2
      expect(request.form_attributes[:Request]).not_to be_blank
      request_id = request.form_attributes[:Request]
      expect(request.form_attributes[:"ItemSubTitle_#{request_id}"]).to eq "Diaries / Diary"
    end
  end
end

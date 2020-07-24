# frozen_string_literal: true
# This spec is modeled on
# https://github.com/projectblacklight/arclight/blob/2336c81e2857f0538dfb57a1297967c29096f9ea/spec/features/traject/ead2_indexing_spec.rb

require "rails_helper"

describe "EAD 2 traject indexing", type: :feature do
  subject(:result) do
    indexer.map_record(record)
  end

  let(:settings) do
    {
      repository: "publicpolicy"
    }
  end

  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new(settings).tap do |i|
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
  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
  end

  describe "solr fields" do
    it "id" do
      expect(result["id"].first).to eq "MC152"
      component_ids = result["components"].map { |component| component["id"].first }
      expect(component_ids).to include "aspace_MC152_c001"
    end
  end

  describe "repository indexing" do
    context "when a Repository has been before the collection is indexed" do
      it "retrieves an existing Repository model and indexes this into Solr" do
        expect(result).to include("repository_ssm" => ["Public Policy Papers"])
        expect(result).to include("repository_sim" => ["Public Policy Papers"])
      end
    end
  end

  describe "container indexing" do
    context "when indexing a collection with deeply nested components" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "ead", "C0614.EAD.xml")
      end

      it "indexes the nested components" do
        components = result["components"]
        child_component_trees = components.select { |c| c["components"].present? }
        child_component_tree = child_component_trees.first
        expect(child_component_tree).to include("id")
        expect(child_component_tree["id"]).to include("aspace_C0614_c00001")
        nested_component_trees = child_component_tree["components"]
        expect(nested_component_trees).not_to be_empty
        nested_component_tree = nested_component_trees.first
        expect(nested_component_tree).to include("id")
        expect(nested_component_tree["id"]).to include("aspace_C0614_c00002")
      end

      it "doesn't index them as top-level components" do
        components = result["components"]
        expect(components.length).to eq 1
        expect(components.group_by { |x| x["id"].first }["C0002_i1"]).to be_blank
      end

      it "doesn't leave empty arrays around" do
        component = result.as_json["components"].first

        expect(component["scopecontent_ssm"]).not_to be_empty
        expect(component["scopecontent_ssm"].length).to eq(3)
        expect(component["scopecontent_ssm"].first).not_to be_empty
      end
    end

    it "indexes deep children without periods" do
      components = result.as_json["components"]
      component = components.first

      expect(component["parent_ssm"]).to eq ["MC152"]

      child_component = component["components"].last
      expect(child_component["parent_ssm"]).to eq ["MC152", "aspace_MC152_c001"]
    end
  end

  describe "digital objects" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "C0776.EAD.xml")
    end

    context "when <dao> is child of the <did> in a <c0x> component" do
      let(:components) { result["components"] }
      let(:dao_components) { components.select { |c| c["digital_objects_ssm"] } }
      let(:component) { dao_components.last }

      it "gets the digital objects" do
        expect(component["digital_objects_ssm"]).to eq(
          [
            JSON.generate(
              label: "Princeton Ethiopic Manuscript No. 84: Magical Prayers to the Virgin Mary",
              href: "https://figgy.princeton.edu/concern/scanned_resources/d93bdf4a-83d1-40cc-ba48-9eeac87a91fc/manifest",
              role: "https://iiif.io/api/presentation/2.1/"
            )
          ]
        )
      end
    end

    context "when <dao> has no role" do
      let(:settings) do
        {
          repository: "mss"
        }
      end
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "ead", "mss", "WC064.EAD.xml")
      end
      let(:component) { result["components"].find { |c| c["id"] == ["aspace_WC064_c1"] } }

      it "gets the digital objects with role: null" do
        json = JSON.generate(
          label: "American Indian man wearing traditional clothing with three white children",
          href: "https://figgy.princeton.edu/concern/scanned_resources/258dc168-da8e-49c3-b239-f3da67cfa896/manifest"
        ).slice(0..-2) + ",\"role\":null}"
        expect(component["digital_objects_ssm"]).to eq(
          [
            json
          ]
        )
      end
    end

    it "gets the title tesim" do
      expect(result["title_teim"]).to include(
        "Princeton Ethiopic Manuscripts"
      )
      expect(result["title_teim"]).to eq(
        result["title_ssm"]
      )
    end

    it "asserts that title filing si field is missing" do
      expect(result["title_filing_si"]).to be_nil
    end

    context "YearRange normalizer tests" do
      let(:dates) { result["normalized_date_ssm"] }
      let(:date_range) { result["date_range_sim"] }
      let(:date) { dates.first }
      let(:years) { date.split("-") }
      let(:beginning) { years.first.to_i }
      let(:ending) { years.last.to_i }

      it "asserts YearRange normalizer works, that normalized_date_ssm contains start and end in date_range_sim field" do
        expect(years).to include(
          beginning.to_s,
          ending.to_s
        )
      end

      it "asserts YearRange normalizer works, the # of yrs in date_range_sim array correct, equal to difference between beginning and ending" do
        # <unitdate normal="1670/1900" type="inclusive">1600s-1900s</unitdate>

        expect(date_range.length).to equal(
          ending - 1670 + 1
        )
      end

      it "asserts YearRange normalizer works, date_range_sim contains a random year between begin and end" do
        expect(result["date_range_sim"]).to include(
          rand(beginning..ending)
        )
      end
    end

    it "gets the normalized date" do
      expect(result["normalized_date_ssm"]).to eq(
        ["1670-1900"]
      )
    end

    it "tests normalized title includes title ssm and normalized date" do
      normal_titles = result["normalized_title_ssm"]
      titles = result["title_ssm"]
      normal_dates = result["normalized_date_ssm"]

      expect(normal_titles.first).to include(
        titles.first,
        normal_dates.first
      )
    end

    describe "collection notes indexing" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221.EAD.xml")
      end

      it "indexes all note fields from the <archdesc> child elements for the collection" do
        expect(result).to include("collection_notes_ssm")
        expect(result["collection_notes_ssm"]).not_to be_empty
        notes = result["collection_notes_ssm"].join
        expect(notes).to include("Harold Boies Hoskins was a businessman, diplomat, and educator working in")
        expect(notes).to include("Born in Beirut and raised by American missionary parents, he")
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")

        expect(result["collection_notes_ssm"]).not_to include("The collection is open for research use.\n            \n")
      end

      it "indexes all note fields from the <archdesc> child elements for the child components" do
        components = result["components"]
        component = components.first

        expect(component).to include("collection_notes_ssm")
        expect(component["collection_notes_ssm"]).not_to be_empty
        notes = component["collection_notes_ssm"].join
        expect(notes).to include("Harold Boies Hoskins was a businessman, diplomat, and educator working in")
        expect(notes).to include("Born in Beirut and raised by American missionary parents, he")
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")

        nested_components = components.flat_map { |c| c["components"] }
        nested_component = nested_components.first

        expect(nested_component).to include("collection_notes_ssm")
        expect(nested_component["collection_notes_ssm"]).not_to be_empty
        notes = nested_component["collection_notes_ssm"].join
        expect(notes).to include("Harold Boies Hoskins was a businessman, diplomat, and educator working in")
        expect(notes).to include("Born in Beirut and raised by American missionary parents, he")
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")
      end
    end
  end

  describe "generating citations" do
    it "generates a citation for any given collection" do
      expect(result).to include("prefercite_ssm")
      expect(result["prefercite_ssm"]).to include("Barr Ferree collection; Public Policy Papers, Department of Special Collections, Princeton University Library")
      expect(result).to include("prefercite_teim")
      expect(result["prefercite_teim"]).to include("Barr Ferree collection; Public Policy Papers, Department of Special Collections, Princeton University Library")
    end

    it "generates a citation for any given component" do
      expect(result).to include("components")
      components = result["components"]
      expect(components).not_to be_empty
      component = components.first

      expect(component).to include("prefercite_ssm")
      expect(component["prefercite_ssm"]).to include("Barr Ferree collection, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library")
      expect(component).to include("prefercite_teim")
      expect(component["prefercite_teim"]).to include("Barr Ferree collection, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library")
    end
  end

  describe "indexing the location information" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "location_aspace.EAD.xml")
    end

    it "indexes the barcode into the barcodes_ssim" do
      expect(result).to include("components")
      components = result["components"]
      expect(components).not_to be_empty
      component = components.first
      expect(component).to include("barcodes_ssim")
      expect(component["barcodes_ssim"]).to include("32101092753019")
    end
  end

  describe "indexing collection component extent values" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC148.EAD.xml")
    end

    it "indexes all extent elements" do
      result
      expect(result).to include("components")
      components = result["components"]
      expect(components.length).to eq(1)
      expect(components.first).to include("components")
      child_components = components.first["components"]
      expect(child_components.length).to eq(9)
      expect(child_components.first).to include("id" => ["MC148_c00002"])
      expect(child_components.last).to include("id" => ["MC148_c00018"])

      expect(result).to include("extent_ssm")
      expect(result["extent_ssm"].length).to eq(2)
      expect(result["extent_ssm"]).to include("278.9 linear feet")
      expect(result["extent_ssm"]).to include("632 boxes and 2 oversize folders")
    end
  end

  describe "#physloc_code_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "WC064.EAD.xml")
    end

    it "resolves and indexes the physical location code" do
      result
      expect(result).to include("physloc_code_ssm")
      expect(result["physloc_code_ssm"]).to eq(["RBSC"])
    end
  end

  describe "#location_code_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "WC064.EAD.xml")
    end

    it "resolves and indexes the location code" do
      result
      expect(result).to include("location_code_ssm")
      expect(result["location_code_ssm"]).to eq(["Firestone Library"])
    end
  end

  describe "#location_note_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "WC064.EAD.xml")
    end

    it "indexes the location note" do
      result
      expect(result).to include("location_note_ssm")
      expect(result["location_note_ssm"]).to eq(["Boxes H4 and H5 (Lummis glass plate negatives) and H6 (California Gold Rush daguerreotype) are stored in special vault facilities."])
    end
  end

  describe "#volume_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
    end

    it "indexes extent values encoding volume numbers" do
      expect(result).to include("components")
      components = result["components"].select { |c| c.key?("volume_ssm") }
      expect(components).not_to be_empty

      expect(components.first).to include("volume_ssm")
      expect(components.first["volume_ssm"]).to eq(["2 Volumes"])
    end
  end
end

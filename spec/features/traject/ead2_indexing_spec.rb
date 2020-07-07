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
        child_component_trees = components.select { |c| c["components"] && !c["components"].empty? }
        child_component_tree = child_component_trees.first
        expect(child_component_tree).to include("id")
        expect(child_component_tree["id"]).to include("aspace_C0614_c00001")
        nested_component_trees = child_component_tree["components"]
        expect(nested_component_trees).not_to be_empty
        nested_component_tree = nested_component_trees.first
        expect(nested_component_tree).to include("id")
        expect(nested_component_tree["id"]).to include("aspace_C0614_c00002")
      end

      # We don't have ArchivesSpace-generated EADs with nested components
      xit "doesn't index them as top-level components" do
        # binding.pry

        components = result["components"]
        expect(components.length).to eq 5
        expect(components.group_by { |x| x["id"].first }["C0002_i1"]).to be_blank
      end
    end

    # This case may not be present in the ArchivesSpace fixtures
    xit "doesn't leave empty arrays around" do
      component = result.as_json["components"].first

      expect(component["scopecontent_ssm"]).not_to be_empty
      expect(component["scopecontent_ssm"].length).to eq(1)
      expect(component["scopecontent_ssm"].first).not_to be_empty
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
        Rails.root.join("spec", "fixtures", "ead", "mss", "WC064-dao-no-role.EAD.xml")
      end
      let(:component) { result["components"].find { |c| c["id"] == ["WC064_c1"] } }

      # This case is not present in the ArchivesSpace fixtures
      xit "gets the digital objects with role: null" do
        json = JSON.generate(
          label: "http://arks.princeton.edu/ark:/88435/m039k5139",
          href: "http://arks.princeton.edu/ark:/88435/m039k5139"
        ).slice(0..-2) + ",\"role\":null}"
        expect(component["digital_objects_ssm"]).to eq(
          [
            json
          ]
        )
      end
    end

    xit "gets the title tesim" do
      expect(result["title_teim"]).to include(
        "Harold B. Hoskins Papers"
      )
      expect(result["title_teim"]).to eq(
        result["title_ssm"]
      )
    end

    it "asserts that title filing si field is missing" do
      expect(result["title_filing_si"]).to be_nil
    end

    context "YearRange normalizer tests" do
      let(:years) { result["normalized_date_ssm"][0].split("-") }
      let(:beginning) { years[0].to_i }
      let(:ending) { years[1].to_i }

      # This needs an updated ArchivesSpace fixture
      xit "asserts YearRange normalizer works, that normalized_date_ssm contains start and end in date_range_sim field" do
        expect(result["normalized_date_ssm"][0]).to include(
          beginning.to_s,
          ending.to_s
        )
      end

      xit "asserts YearRange normalizer works, the # of yrs in date_range_sim array correct, equal to difference between beginning and ending" do
        expect(result["date_range_sim"].length).to equal(
          ending - beginning + 1
        )
      end

      it "asserts YearRange normalizer works, date_range_sim contains a random year between begin and end" do
        expect(result["date_range_sim"]).to include(
          rand(beginning..ending)
        )
      end
    end

    xit "gets the normalized date" do
      expect(result["normalized_date_ssm"]).to eq(
        ["1822-1982"]
      )
    end

    # This requires an ArchivesSpace fixture
    xit "tests normalized title includes title ssm and normalized date" do
      expect(result["normalized_title_ssm"][0]).to include(
        result["title_ssm"][0],
        result["normalized_date_ssm"][0]
      )
    end
  end

  describe "generating citations" do
    xit "generates a citation for any given collection" do
      expect(result).to include("prefercite_ssm" => ["Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections, Princeton University Library"])
      expect(result).to include("prefercite_teim" => ["Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections, Princeton University Library"])
    end

    xit "generates a citation for any given component" do
      expect(result).to include("components")
      components = result["components"]
      expect(components).not_to be_empty
      component = components.first
      expect(component).to include("prefercite_ssm" => ["Harold B. Hoskins Papers, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library"])
      expect(component).to include("prefercite_teim" => ["Harold B. Hoskins Papers, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library"])
    end
  end
end

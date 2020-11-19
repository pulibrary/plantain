# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component show page" do
    it "renders a collection title as a link without a separate date element" do
      visit "catalog/aspace_MC221_c0059"
      expect(page).to have_css(".collection.title a span", text: "Harold B. Hoskins Papers, 1822-1982")
      expect(page).not_to have_css(".collection-attributes h2.media span.col")
    end
    it "has a suggest a correction form", js: false do
      visit "catalog/aspace_MC221_c0059"

      expect(page).to have_field "suggest_a_correction_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
      expect(page).to have_field "suggest_a_correction_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/aspace_MC221_c0059"
    end
  end
  context "when viewing a component which can be requested from Aeon" do
    xit "renders a request button" do
      visit "/catalog/aspace_MC148_c00001"

      # This is now blocked by the Request Cart Vue integration
    end

    xit "generates a request <form>" do
      visit "/catalog/aspace_WC064_c1"

      # This is now blocked by the Request Cart Vue integration
    end

    context "with extent provided" do
      xit "maps this to the <form> <input>" do
        visit "/catalog/aspace_MC148_c00001"

        # This is now blocked by the Request Cart Vue integration
      end
    end
  end
  context "with a component show page" do
    before do
      visit "/catalog/aspace_MC221_c0060"
    end

    it "has a table of contents element" do
      expect(page).to have_css("#toc")
    end

    it "does not have breadcrumbs" do
      expect(page).not_to have_css("ol.breadcrumb")
    end

    it "has a collection history tab" do
      expect(page.body).to include "Scott Rodman approved the gifting to Mudd"
      expect(page.body).to include "Gifted to the American Heritage Center"
      expect(page.body).to include "boxes of books were separated during processing in 2007"
      expect(page.body).to include "A preliminary inventory list, MARC record and collection-level description"
      expect(page.body).to include "These papers were processed with the generous support"
    end

    it "has a collection access tab", js: false do
      # accessrestrict
      expect(page.body).to include "The collection is open for research use."
      # userestrict
      expect(page.body).to include "Conditions for Reproduction and Use"
      expect(page.body).to include "Single photocopies may be made for research purposes"
      expect(page.body).to include "Public Policy Papers, Department of Special Collections"
      expect(page.body).to include "65 Olden Street"
      expect(page.body).to include "(609) 258-6345"
      expect(page.body).to have_link "U. S. Copyright Law", href: "http://copyright.princeton.edu/basics/fair-use", visible: false
    end

    it "has a find related materials tab" do
      expect(page.body).to include "Topics"
      expect(page.body).to include "20th century"
      expect(page.body).to include "Subject Terms"
      expect(page.body).to include "Missionaries"
      expect(page.body).to include "Genre Terms"
      expect(page.body).to include "Correspondence"
      expect(page.body).to include "Names"
      expect(page.body).to include "Foreign Service Institute"
      expect(page.body).to include "Places"
      expect(page.body).to include "Middle East -- Politics"
    end
    context "which has a viewer", js: false do
      before do
        visit "/catalog/aspace_MC221_c0094"
      end
      it "displays the viewer" do
        expect(page).to have_css(".uv__overlay")
      end
    end
  end
  context "with a collection show page" do
    before do
      visit "/catalog/MC221"
    end

    it "has a suggest a correction form", js: false do
      expect(page).to have_field "suggest_a_correction_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/MC221"
      expect(page).to have_field "suggest_a_correction_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
    end

    it "has overview and abstract summary sections" do
      # Collection name records not in aspace data yet.
      # expect(page).to have_css(".blacklight-creators_ssim a", text: "Hoskins")
      expect(page).to have_css("dd.blacklight-title_ssm", text: "Harold B. Hoskins Papers")
      expect(page).to have_css("dd.blacklight-normalized_date_ssm", text: "1822-1982")
      expect(page).to have_css("dd.blacklight-extent_ssm", text: "17 boxes")
      expect(page).to have_text("Harold Boies Hoskins was a businessman")
      expect(page).to have_text "unavailable until further notice"
    end
    xit "has a language property in the overview summary section" do
      # TODO: ensure that collection language is indexed correctly
      expect(page).to have_css("dd.blacklight-language_ssm", text: "English")
    end

    it "has description and creator biography metadata" do
      expect(page.body).to include "This collection consists of correspondence, diaries, notes, photographs,"
      expect(page.body).to include "Harold Boies Hoskins was a businessman, diplomat, and educator"
    end

    it "has a collection history tab" do
      expect(page.body).to include "Scott Rodman approved the gifting to Mudd"
      expect(page.body).to include "Gifted to the American Heritage Center"
      expect(page.body).to include "boxes of books were separated during processing in 2007"
      expect(page.body).to include "A preliminary inventory list, MARC record and collection-level description"
      expect(page.body).to include "These papers were processed with the generous support"
    end

    it "has a collection access tab" do
      expect(page.body).to include "The collection is open for research use."
      expect(page.body).to include "Single photocopies may be made for research purposes"
      expect(page.body).to include "Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections"
      expect(page.body).to include "65 Olden Street"
      expect(page.body).to include "(609) 258-6345"
    end

    it "has a find related materials tab" do
      expect(page.body).to include "Topics"
      expect(page.body).to include "20th century"
      expect(page.body).to include "Subject Terms"
      expect(page.body).to include "Missionaries"
      expect(page.body).to include "Genre Terms"
      expect(page.body).to include "Correspondence"
      # Commented out these two - names are not currently in our aspace
      # instance data.
      # TODO: Put these back.
      # expect(page.body).to include "Names"
      # expect(page.body).to include "Foreign Service Institute"
      expect(page.body).to include "Places"
      expect(page.body).to include "Middle East -- Politics"
    end
  end
  context "when a component has a digital object with a manifest" do
    before do
      visit "/catalog/aspace_MC221_c0094"
    end

    it "renders the universal viewer" do
      manifest_url = "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest"
      iframe = "<iframe src=\"https://figgy.princeton.edu/viewer#?manifest=#{manifest_url}\" allowfullscreen=\"true\"></iframe>"
      expect(page.body).to include iframe
    end
  end
  context "when a component has a digital object with a link" do
    before do
      visit "/catalog/aspace_MC148_c07608"
    end

    it "renders a view content link" do
      url = "https://webspace.princeton.edu/users/mudd/Digitization/MC148/MC148_c07608.pdf"
      expect(page).to have_css("a[href=\"#{url}\"]")
    end
  end

  describe "notes", js: false do
    context "on a collection page" do
      it "shows all the relevant notes" do
        visit "/catalog/MC148"

        # Collection Description
        within("#description") do
          # Description
          expect(page).to have_selector "dt.blacklight-collection_description_ssm", text: "Description"
          expect(page).to have_selector "dd.blacklight-collection_description_ssm", text: /This collection consists of the papers of Lilienthal/
          # Arrangement
          expect(page).to have_selector "dt.blacklight-arrangement_ssm", text: "Arrangement"
          expect(page).to have_selector "dd.blacklight-arrangement_ssm", text: /may have been put in this order by Lilienthal/
        end

        # Access Restrictions
        within("#access") do
          # Access Restrictions
          expect(page).to have_selector "dt.blacklight-accessrestrict_ssm", text: "Access Restrictions"
          expect(page).to have_selector "dd.blacklight-accessrestrict_ssm", text: /LINKED DIGITAL CONTENT NOTE:/
          # Use Restrictions
          expect(page).to have_selector "dt.blacklight-userestrict_ssm", text: "Conditions for Reproduction and Use"
          expect(page).to have_selector "dd.blacklight-userestrict_ssm", text: /Single photocopies/
          # Special Requirements
          expect(page).to have_selector "dt.blacklight-phystech_ssm", text: "Special Requirements for Access"
          expect(page).to have_selector "dd.blacklight-phystech_ssm", text: /Access to audiovisual material/
        end
      end
      it "shows otherfindaid" do
        visit "/catalog/MC001-02-06"
        # Access Restrictions
        within("#access") do
          expect(page).to have_selector "dt.blacklight-otherfindaid_ssm", text: "Other Finding Aids"
          expect(page).to have_selector "dd.blacklight-otherfindaid_ssm", text: /This finding aid describes a portion/
        end
      end
    end
  end
end

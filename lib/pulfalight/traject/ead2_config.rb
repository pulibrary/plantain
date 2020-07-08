# frozen_string_literal: true

require "logger"
require "traject"
require "traject/nokogiri_reader"
require "traject_plus"
require "traject_plus/macros"
require "arclight/level_label"
require "arclight/normalized_date"
require "arclight/normalized_title"
require "active_model/conversion" ## Needed for Arclight::Repository
require "active_support/core_ext/array/wrap"
require Rails.root.join("app", "overrides", "arclight", "digital_object_override")
require "arclight/year_range"
require "arclight/repository"
require "arclight/missing_id_strategy"
require "arclight/traject/nokogiri_namespaceless_reader"
require_relative "../normalized_title"
require_relative "../normalized_date"
require_relative "../year_range"
require Rails.root.join("lib", "pulfalight", "traject", "ead2_indexing")

extend TrajectPlus::Macros
self.class.include(Pulfalight::Ead2Indexing)

# Configure the settings before the Document is indexed
configure_before

# ==================
# Top level document
# ==================

# rubocop:disable Performance/StringReplacement
to_field "id", extract_xpath("/ead/eadheader/eadid"), strip, gsub(".", "-")
# rubocop:enable Performance/StringReplacement
to_field "title_filing_si", extract_xpath('/ead/eadheader/filedesc/titlestmt/titleproper[@type="filing"]')
to_field "title_ssm", extract_xpath("/ead/archdesc/did/unittitle")
to_field "title_teim", extract_xpath("/ead/archdesc/did/unittitle")
to_field "ead_ssi", extract_xpath("/ead/eadheader/eadid")

to_field "unitdate_ssm", extract_xpath("/ead/archdesc/did/unitdate")
to_field "unitdate_bulk_ssim", extract_xpath('/ead/archdesc/did/unitdate[@type="bulk"]')
to_field "unitdate_inclusive_ssm", extract_xpath('/ead/archdesc/did/unitdate[@type="inclusive"]')
to_field "unitdate_other_ssim", extract_xpath("/ead/archdesc/did/unitdate[not(@type)]")

# All top-level docs treated as 'collection' for routing / display purposes
to_field "level_ssm" do |_record, accumulator|
  accumulator << "collection"
end

# Keep the original top-level archdesc/@level for Level facet in addition to 'Collection'
to_field "level_sim" do |record, accumulator|
  archdesc = record.at_xpath("/ead/archdesc")
  unless archdesc.nil?

    level = archdesc.attribute("level")&.value
    other_level = archdesc.attribute("otherlevel")&.value

    accumulator << Arclight::LevelLabel.new(level, other_level).to_s
    accumulator << "Collection" unless level == "collection"
  end
end

to_field "unitid_ssm", extract_xpath("/ead/archdesc/did/unitid")
to_field "unitid_teim", extract_xpath("/ead/archdesc/did/unitid")
to_field "collection_unitid_ssm", extract_xpath("/ead/archdesc/did/unitid")

to_field "normalized_title_ssm" do |_record, accumulator, context|
  dates = Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s

  titles = context.output_hash["title_ssm"]
  unless titles.blank?
    title = titles.first
    accumulator << Pulfalight::NormalizedTitle.new(title, dates).to_s
  end
end

to_field "normalized_date_ssm" do |_record, accumulator, context|
  accumulator << Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s
end

to_field "collection_ssm" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_sim" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_ssi" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_title_tesim" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end

to_field "repository_ssm" do |_record, accumulator, context|
  accumulator << context.clipboard[:repository]
end

to_field "repository_sim" do |_record, accumulator, context|
  accumulator << context.clipboard[:repository]
end

to_field "geogname_ssm", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "geogname_sim", extract_xpath("/ead/archdesc/controlaccess/geogname")

to_field "creator_ssm", extract_xpath("/ead/archdesc/did/origination")
to_field "creator_sim", extract_xpath("/ead/archdesc/did/origination")
to_field "creator_ssim", extract_xpath("/ead/archdesc/did/origination")
to_field "creator_sort" do |record, accumulator|
  accumulator << record.xpath("/ead/archdesc/did/origination").map { |c| c.text.strip }.join(", ")
end

to_field "creator_persname_ssm", extract_xpath("/ead/archdesc/did/origination/persname")
to_field "creator_persname_ssim", extract_xpath("/ead/archdesc/did/origination/persname")
to_field "creator_corpname_ssm", extract_xpath("/ead/archdesc/did/origination/corpname")
to_field "creator_corpname_sim", extract_xpath("/ead/archdesc/did/origination/corpname")
to_field "creator_corpname_ssim", extract_xpath("/ead/archdesc/did/origination/corpname")
to_field "creator_famname_ssm", extract_xpath("/ead/archdesc/did/origination/famname")
to_field "creator_famname_ssim", extract_xpath("/ead/archdesc/did/origination/famname")

to_field "persname_sim", extract_xpath("//persname")

to_field "creators_ssim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["creator_persname_ssm"] if context.output_hash["creator_persname_ssm"]
  accumulator.concat context.output_hash["creator_corpname_ssm"] if context.output_hash["creator_corpname_ssm"]
  accumulator.concat context.output_hash["creator_famname_ssm"] if context.output_hash["creator_famname_ssm"]
end

to_field "places_sim", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "places_ssim", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "places_ssm", extract_xpath("/ead/archdesc/controlaccess/geogname")

to_field "access_terms_ssm", extract_xpath('/ead/archdesc/userestrict/*[local-name()!="head"]')

to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash.fetch("acqinfo_ssim", []))
end

to_field "access_subjects_ssim", extract_xpath("/ead/archdesc/controlaccess", to_text: false) do |_record, accumulator|
  accumulator.map! do |element|
    %w[subject function occupation genreform].map do |selector|
      element.xpath(".//#{selector}").map(&:text)
    end
  end.flatten!
end

to_field "access_subjects_ssm" do |_record, accumulator, context|
  accumulator.concat Array.wrap(context.output_hash["access_subjects_ssim"])
end

to_field "has_online_content_ssim", extract_xpath(".//dao") do |_record, accumulator|
  accumulator.replace([accumulator.any?])
end

to_field "digital_objects_ssm", extract_xpath("/ead/archdesc/did/dao|/ead/archdesc/dao", to_text: false) do |_record, accumulator|
  accumulator.map! do |dao|
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    role = (dao.attributes["role"] || dao.attributes["xlink:role"])&.value
    Arclight::DigitalObject.new(label: label, href: href, role: role).to_json
  end
end

to_field "extent_ssm", extract_xpath("/ead/archdesc/did/physdesc/extent")
to_field "extent_teim", extract_xpath("/ead/archdesc/did/physdesc/extent")
to_field "genreform_sim", extract_xpath("/ead/archdesc/controlaccess/genreform")
to_field "genreform_ssm", extract_xpath("/ead/archdesc/controlaccess/genreform")

to_field "date_range_sim", extract_xpath("/ead/archdesc/did/unitdate/@normal", to_text: false) do |_record, accumulator|
  range = Pulfalight::YearRange.new
  next range.years if accumulator.blank?

  ranges = accumulator.map(&:to_s)
  range << range.parse_ranges(ranges)
  accumulator.replace range.years
end

SEARCHABLE_NOTES_FIELDS.map do |selector|
  to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']")
  to_field "#{selector}_heading_ssm", extract_xpath("/ead/archdesc/#{selector}/head")
  to_field "#{selector}_teim", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']")
end

DID_SEARCHABLE_NOTES_FIELDS.map do |selector|
  to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/did/#{selector}")
end

NAME_ELEMENTS.map do |selector|
  to_field "names_coll_ssim", extract_xpath("/ead/archdesc/controlaccess/#{selector}")
  to_field "names_ssim", extract_xpath("//#{selector}")
  to_field "#{selector}_ssm", extract_xpath("//#{selector}")
end

to_field "corpname_sim", extract_xpath("//corpname")

to_field "language_sim", extract_xpath("/ead/archdesc/did/langmaterial")
to_field "language_ssm", extract_xpath("/ead/archdesc/did/langmaterial")

to_field "descrules_ssm", extract_xpath("/ead/eadheader/profiledesc/descrules")

to_field "prefercite_ssm" do |_record, accumulator, context|
  titles = context.output_hash["title_ssm"]
  title = titles.first
  output = "#{title}; "
  citation = CitationResolverService.resolve(repository_id: settings["repository"])
  if citation
    output += citation
    output += ", Princeton University Library"

    accumulator << output unless output.empty?
  end
end

to_field "prefercite_teim" do |_record, accumulator, context|
  accumulator.concat Array.wrap(context.output_hash["prefercite_ssm"])
end

to_field "components" do |record, accumulator, context|
  xpath = if record.is_a?(Nokogiri::XML::Document)
            "/ead/archdesc/dsc/*[is_component(.)][@level != 'otherlevel']"
          else
            "./*[is_component(.)][@level != 'otherlevel']"
          end
  child_components = record.xpath(xpath, Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new)
  child_components.each do |child_component|
    component_indexer = build_component_indexer(context)
    output = component_indexer.map_record(child_component)
    accumulator << output
  end
end

# Configure the settings after the Document is indexed
configure_after

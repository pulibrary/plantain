# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Arclight::SearchBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:remove_grouping, :boost_collections]

  def remove_grouping(solr_params)
    # Remove grouping parameters if faceting by collection
    Arclight::Engine.config.catalog_controller_group_query_params.keys.each { |k| solr_params.delete(k) } if blacklight_params.dig(:f, :collection_sim)
    solr_params
  end

  def boost_collections(solr_params)
    solr_params[:bq] ||= []
    solr_params[:bq] << "level_ssm:collection^5"
  end
end

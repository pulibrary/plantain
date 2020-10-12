# frozen_string_literal: true
module Aspace
  class Client < ArchivesSpace::Client
    def self.config
      ArchivesSpace::Configuration.new({
                                         base_uri: Pulfalight.config["archivespace_url"],
                                         username: Pulfalight.config["archivespace_user"],
                                         password: Pulfalight.config["archivespace_password"],
                                         page_size: 50,
                                         throttle: 0
                                       })
    end

    def initialize
      super(self.class.config)
      login
    end

    def ead_urls
      output = recent_repositories.flat_map do |repository|
        config.base_repo = repository["uri"][1..-1]
        resource_ids = self.get("resources", query: { all_ids: true }).parsed
        resource_ids.map do |resource_id|
          "#{config.base_repo}/resource_descriptions/#{resource_id}"
        end
      end
      config.base_repo = ""
      output
    end

    def recent_repositories
      repositories.select do |repository|
        Time.zone.parse(repository["create_time"]) > Time.zone.parse("2020-01-01")
      end
    end
  end
end

# frozen_string_literal: true

module Pulfalight
  module Requests
    class AeonExternalRequest < Arclight::Requests::AeonExternalRequest
      include Rails.application.routes.url_helpers

      def config
        @config ||= begin
                      yaml_file_path = "config/aeon.yml"
                      yaml_file = File.read(yaml_file_path)
                      YAML.safe_load(yaml_file)
                    end
      end

      def form_mapping
        super.merge(dynamic_field_mappings)
      end

      def static_mappings
        request_mappings.merge(super)
      end

      def url_params
        return unless config.key?("url_params")

        config["url_params"].to_query
      end

      def url
        return configured_request_url unless url_params

        "#{configured_request_url}?#{url_params}"
      end

      def containers
        values = @document.containers.map do |container|
          { type: container.type, value: container.value }
        end

        JSON.generate(values)
        values
      end

      def subcontainers
        values = @document.subcontainers.map do |container|
          { type: container.type, value: container.value }
        end

        JSON.generate(values)
        values
      end

      def eadid
        Array.wrap(@document.eadid).first
      end

      def extent
        Array.wrap(@document.extent).first
      end

      def accessnote
        value = @document.acqinfo.first.to_s
        # This needs to be moved into the Traject configuration
        value.gsub(/\t+/, " ").delete("\n")
      end

      def id
        @document.barcode.first
      end
      alias request_id id

      def barcode
        @document.barcode.first || @document.id
      end

      def unitid
        {
          type: "barcode",
          value: barcode
        }
      end

      def self.hash_value?(field)
        [
          :unitid,
          :containers,
          :subcontainers
        ].include?(field.to_sym)
      end

      def physdesc_number
        @document.physdesc_number.empty? ? ["1"] : @document.physdesc_number
      end

      def physical_location_code
        @document.physical_location_code.first
      end

      def itemvolume
        top_container_type = @document.container_types.first
        first_value = top_container_type.gsub(/\s+?\d+/, "")
        values = [first_value]
        values << @document.id
        values.join(" ")
      end

      def attributes
        {
          callnumber: eadid,
          referencenumber: eadid,
          title: @document.title.first,
          containers: containers, # add this,
          subcontainers: subcontainers, # add this
          unitid: unitid,
          physloc: @document.physical_location_code.first,
          location: @document.location.first,
          subtitle: @document.subtitle.first,
          itemdate: @document.normalized_date.first,
          itemnumber: id,
          itemvolume: itemvolume,
          accessnote: accessnote,
          extent: extent,
          itemurl: url
        }
      end

      private

      def default_url_options
        Rails.application.config.action_controller.default_url_options
      end

      def request_mappings
        {
          Request: id
        }
      end

      def default_dynamic_fields
        {
          "Request" => id,
          "CallNumber_#{id}" => @document.id,
          "ItemTitle_#{id}" => @document.title.first,
          "ItemTitle" => @document.title.first,
          "ItemSubTitle_#{id}" => @document.subtitle.first,
          "ItemAuthor_#{id}" => @document.collection_creator,
          "ItemDate_#{id}" => @document.normalized_date.first,
          "ItemNumber_#{id}" => id,
          "ItemVolume_#{id}" => itemvolume,
          "ItemInfo1_#{id}" => accessnote,
          "ItemInfo2_#{id}" => extent,
          "ItemInfo3_#{id}" => physdesc_number.first,
          "ItemInfo4_#{id}" => @document.location_note.join(","),
          "ItemInfo5_#{id}" => url,
          "Location_#{id}" => @document.location_code, # Example: mudd
          "Location" => @document.location_code.first,
          "ReferenceNumber_#{id}" => @document.id,
          "DocumentType": "Manuscript",
          "Site": @document.location_code.first,
          "SubmitButton": "Submit Request"
        }
      end

      def dynamic_field_mappings
        default_dynamic_fields
      end

      def configured_request_url
        config.fetch("request_url")
      rescue KeyError => key_error
        Rails.logger.error("No request service URL is configured for Aeon in config/aeon.yml")
        raise key_error
      end
    end
  end
end

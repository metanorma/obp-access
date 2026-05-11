# frozen_string_literal: true

module Obp
  class Access
    class Deliverable
      TYPE_SEGMENTS = {
        "IS" => nil, "TS" => "ts", "TR" => "tr", "R" => "r",
        "PAS" => "pas", "ISP" => "isp", "GUIDE" => "guide",
        "IWA" => "iwa", "DATA" => "data", "TTA" => "tta"
      }.freeze

      TYPE_WORDS = Set.new(TYPE_SEGMENTS.compact.keys).freeze

      PUBLISHED_STAGES = [6060, 9092].freeze

      attr_reader :id, :reference, :deliverable_type, :edition, :current_stage,
                  :languages, :supplement_type, :title, :publication_date,
                  :ics_codes, :owner_committee

      def initialize(data)
        @id = data["id"]
        assign_metadata(data)
      end

      def published?
        PUBLISHED_STAGES.include?(current_stage)
      end

      def base_document?
        supplement_type.nil?
      end

      def retrievable?
        published? && base_document? && languages.any?
      end

      def to_urn(language: "en")
        Urn.new(build_urn(language))
      end

      def english_title
        title["en"]
      end

      private

      def assign_metadata(data)
        @reference = data["reference"]
        @deliverable_type = data["deliverableType"]
        @edition = data["edition"]
        @current_stage = data["currentStage"]
        @supplement_type = data["supplementType"]
        @publication_date = data["publicationDate"]
        @owner_committee = data["ownerCommittee"]
        assign_collections(data)
      end

      def assign_collections(data)
        @languages = Array(data["languages"])
        @title = data["title"] || {}
        @ics_codes = Array(data["icsCode"])
      end

      def build_urn(language)
        segs = ["iso", "std", org_segment]
        type_seg = TYPE_SEGMENTS[deliverable_type]
        segs << type_seg if type_seg
        segs << extract_number
        segs << "-#{extract_part}" if extract_part
        segs << "ed-#{edition}"
        segs << "v1"
        segs << language
        segs.join(":")
      end

      def org_segment
        @org_segment ||= begin
          tokens = parse_prefix_tokens
          rest = tokens[1..] || []
          org_tokens = rest.reject { |t| TYPE_WORDS.include?(t) }
          org_tokens.empty? ? "iso" : "iso-#{org_tokens.join('-').downcase}"
        end
      end

      def extract_number
        @extract_number ||= begin
          match = base_reference.match(/(\d+)(?:-\d+)?:\d{4}/)
          match ? match[1] : "0"
        end
      end

      def extract_part
        @extract_part ||= begin
          match = base_reference.match(/\d+-(\d+):\d{4}/)
          match ? match[1] : nil
        end
      end

      def parse_prefix_tokens
        prefix = base_reference.match(/\A(.+?)\s+\d/)&.[](1) || "ISO"
        prefix.split(%r{[/\s]+})
      end

      def base_reference
        @base_reference ||= reference.sub(%r{/(?:Amd|Cor)\s+\d+(?::\d+)?$}, "")
      end
    end
  end
end

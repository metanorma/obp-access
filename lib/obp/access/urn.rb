module Obp
  class Access
    class Urn
      DOC_TYPE_SEGMENTS = %w[ts tr pas guide iwa].freeze

      attr_reader :raw, :language, :base

      def initialize(raw)
        @raw = raw
        parts = raw.split(":")
        @language = parts.last
        @base = parts[0...-1].join(":")
      end

      def safe
        @safe ||= raw.tr(":", "-")
      end

      def to_s
        raw
      end

      def ==(other)
        other.is_a?(self.class) && raw == other.raw
      end
      alias_method :eql?, :==

      def hash
        raw.hash
      end

      def parts
        @parts ||= raw.split(":")
      end

      # Originator segment: "iso", "iec", "itu", ...
      def originator
        parts[2]
      end

      # Document type segment if present ("ts", "tr", ...), else nil
      def doc_type_segment
        segments = identifier_segments
        segments.find { |s| DOC_TYPE_SEGMENTS.include?(s) }
      end

      # Document number, including part number when present.
      # "iso:std:iso:80000:-12:ed-2:v1:en" → "80000-12"
      def doc_number
        identifier_segments
          .reject { |s| DOC_TYPE_SEGMENTS.include?(s) }
          .join
      end

      def edition
        segment = parts.find { |p| p.start_with?("ed-") }
        segment&.delete_prefix("ed-")
      end

      def version
        segment = parts.find { |p| p.match?(/\Av\d+\z/) }
        segment&.delete_prefix("v")
      end

      def doc_type
        case doc_type_segment
        when "ts" then "TS"
        when "tr" then "TR"
        when "pas" then "PAS"
        when "guide" then "Guide"
        when "iwa" then "IWA"
        else "IS"
        end
      end

      private

      # Segments between the originator and the edition segment.
      def identifier_segments
        start_index = 3
        end_index = parts.index { |p| p.start_with?("ed-") } || parts.size
        parts[start_index...end_index]
      end
    end
  end
end

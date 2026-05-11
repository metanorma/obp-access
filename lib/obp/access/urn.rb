module Obp
  class Access
    class Urn
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
    end
  end
end

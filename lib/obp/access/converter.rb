module Obp
  module Access
    class Converter
      attr_reader :urn, :source

      def initialize(urn:, source:)
        @urn = urn
        @source = source
      end

      def to_xml
        rendered = Rendered.new(urn:, nodes:)
        rendered.to_xml
      end

      private

      def nodes
        html = source.gsub(/[[:space:]]/, " ") # Convert NBSP to spaces from html
        doc = Nokogiri::HTML(html)
        doc.css("body > div.sts-standard").children
      end
    end
  end
end

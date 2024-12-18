module Obp
  module Access
    class Converter
      attr_reader :urn, :metas, :source

      def initialize(urn:, metas:, source:)
        @urn = urn
        @metas = metas
        @source = source
      end

      def to_xml
        rendered = Renderer.new(urn:, metas:, nodes:)
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

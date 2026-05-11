module Obp
  class Access
    class Converter
      attr_reader :urn, :metas, :source

      def initialize(urn:, metas:, source:)
        @urn = urn
        @metas = metas
        @source = source
      end

      def to_xml
        Renderer.new(urn:, metas:, nodes:).to_xml
      end

      private

      def nodes
        html = source.gsub(/[[:space:]]/, " ")
        doc = Nokogiri::HTML(html)
        doc.css("body > div.sts-standard").children
      end
    end
  end
end

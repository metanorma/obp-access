require_relative "converter/base"

module Obp
  module Access
    class Converter
      attr_reader :urn, :source, :document

      def initialize(urn:, source:)
        @urn = urn
        @source = source
        @document = Sections::Root.new(urn:).to_document
      end

      def to_xml
        nodes.map { |node| Converter.render_sections(document:, node:) }

        xml_output = document.root.to_xml
        pp xml_output
      end

      private

      def nodes
        html = source.gsub(/[[:space:]]/, " ") # Convert NBSP to spaces from html
        doc = Nokogiri::HTML(html)
        doc.css("body > div.sts-standard > div.sts-section") # Find all direct sections from HTML
      end
    end
  end
end

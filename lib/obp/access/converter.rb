require_relative "converter/elements"
require_relative "converter/elements/base"
require_relative "converter/elements/introduction"
require_relative "converter/elements/section"

module Obp
  module Access
    class Converter
      attr_reader :urn, :source

      def initialize(urn:, source:)
        @urn = urn
        @source = source
      end

      def to_xml
        doc = Nokogiri::XML(builder.to_xml)

        # FIXME: Can't determine 'sec-type' attr from HTML
        nodes.map do |node|
          Elements.descendants.map do |descendant|
            element = descendant.new(node:)
            next unless element.match_node?

            doc.at(element.target).add_child(element.to_xml)
          end
        end

        doc.root.to_xml
      end

      private

      def nodes
        # Find all direct sections from HTML
        doc = Nokogiri::HTML(source)
        doc.css("body > div.sts-standard > div.sts-section")
      end

      def builder
        Nokogiri::XML::Builder.new do |xml|
          xml.standard("xmlns:xlink": "http://www.w3.org/1999/xlink",
                       "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                       "xmlns:tbx": urn,
                       id: "e1d18be9",
                       "xml:lang": "en") do
            xml.front
            xml.body
          end
        end
      end
    end
  end
end

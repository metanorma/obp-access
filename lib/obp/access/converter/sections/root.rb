module Obp
  module Access
    class Converter
      class Sections
        class Root
          attr_reader :urn

          def initialize(urn:)
            @urn = urn
          end

          def content
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

          def to_document
            content.doc
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Converter
      class Elements
        class Root
          attr_reader :urn

          def initialize(urn:)
            @urn = urn
          end

          def to_xml
            Nokogiri::XML::Builder.new do |xml|
              xml.standard("xmlns:xlink": "http://www.w3.org/1999/xlink",
                           "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                           "xmlns:tbx": urn,
                           id: "e1d18be9",
                           "xml:lang": "en") do
                xml.front
                xml.body
              end
            end.to_xml
          end
        end
      end
    end
  end
end

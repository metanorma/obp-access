module Obp
  module Access
    class Converter
      class Sections
        class Introduction < Base
          def match_node?
            id == "intro"
          end

          def target
            :front
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec("sec-type": "intro", "specific-use": "introduction.int", id: "introduction.int") do
                Converter.render_elements(node:, xml:)
              end
            end
          end
        end
      end
    end
  end
end

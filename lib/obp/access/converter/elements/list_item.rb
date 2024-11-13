module Obp
  module Access
    class Converter
      class Elements
        class ListItem < Base
          def match_node?
            node.name == "li"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"list-item") do
                xml.label "test"
              end
            end
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Converter
      class Elements
        class Paragraph < Base
          def match_node?
            # Paragraph in a list are rendered differently
            node.name == "div" && node.attr("class") == "sts-p" && node.parent.name != "li"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.p node.content.strip
            end
          end
        end
      end
    end
  end
end

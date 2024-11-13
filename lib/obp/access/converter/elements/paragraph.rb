module Obp
  module Access
    class Converter
      class Elements
        class Paragraph < Base
          def match_node?
            node.name == "div" && node.attr("class") == "sts-p"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.p node.content
            end
          end
        end
      end
    end
  end
end

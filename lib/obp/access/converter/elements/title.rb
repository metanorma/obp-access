module Obp
  module Access
    class Converter
      class Elements
        class Title < Base
          def match_node?
            node.name == "h1" && node.attr("class") == "sts-sec-title"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.title node.content.strip
            end
          end
        end
      end
    end
  end
end

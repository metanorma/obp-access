module Obp
  module Access
    class Converter
      class Elements
        class List < Base
          def match_node?
            node.name == "div" && node.attr("class") == "list"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.list("list-type": "alpha-lower") do

              end
            end
          end
        end
      end
    end
  end
end

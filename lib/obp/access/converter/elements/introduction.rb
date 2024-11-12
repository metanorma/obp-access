module Obp
  module Access
    class Converter
      class Elements
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
                xml.title title
                node.search("> div.sts-p").map do |p|
                  xml.p p.content
                end
              end
            end
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Rendered
      class Elements
        class Introduction < Base
          def self.selector
            "div.sts-section"
          end

          def match_node?
            # Section introduction ids finishes with "intro"
            super && id == "intro"
          end

          def target
            :front
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec("sec-type": "intro", "specific-use": "introduction.int", id: "introduction.int")
            end
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Rendered
      class Elements
        class Paragraph < Base
          def self.classes
            %w[sts-p]
          end

          def match_node?
            # Paragraph in a list are rendered within the list element
            super && node.parent.name != "li"
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

module Obp
  class Access
    class Renderer
      class Elements
        class Title < Base
          def self.classes
            %w[sts-sec-title]
          end

          def insert_using
            :prepend_child # In this XML, order matters. This node needs to appear at the top of the XML section
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.title sanitize_text(node.content)
            end
          end
        end
      end
    end
  end
end

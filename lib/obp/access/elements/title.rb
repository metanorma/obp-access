module Obp
  module Access
    class Rendered
      class Elements
        class Title < Base
          def self.classes
            %w[sts-sec-title]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.title sanitize_text(node.content.strip)
            end
          end
        end
      end
    end
  end
end

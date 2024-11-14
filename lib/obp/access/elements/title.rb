module Obp
  module Access
    class Rendered
      class Elements
        class Title < Base
          def self.selector
            "h1.sts-sec-title, div.sts-tbx-term"
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

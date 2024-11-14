module Obp
  module Access
    class Rendered
      class Elements
        class Section < Base
          def self.selector
            "div.sts-section"
          end

          def match_node?
            # Section ids finishes with an integer or decimal
            super && id =~ /\A\d+(\.\d+)*\z/
          end

          def target
            :body
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              # FIXME: Can't determine 'sec-type' attr from HTML
              xml.sec(id: "sub-#{id}", "sec-type": "FIXME") do
                xml.label id
              end
            end
          end
        end
      end
    end
  end
end

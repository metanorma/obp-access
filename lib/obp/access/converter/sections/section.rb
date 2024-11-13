module Obp
  module Access
    class Converter
      class Sections
        class Section < Base
          def match_node?
            id =~ /\A\d+\Z/
          end

          def target
            :body
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              # FIXME: Can't determine 'sec-type' attr from HTML
              xml.sec(id: "sub-#{id}", "sec-type": "FIXME") do
                xml.label id
                Converter.render_elements(node:, xml:)
              end
            end
          end
        end
      end
    end
  end
end

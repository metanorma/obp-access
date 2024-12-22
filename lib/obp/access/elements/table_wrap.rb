module Obp
  module Access
    class Renderer
      class Elements
        class TableWrap < Base
          def self.classes
            %w[sts-table-wrap fig-index]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"table-wrap") do
                xml.label label if label
                if caption
                  xml.caption do
                    xml.title caption
                  end
                end
                xml.table { xml << node.at_css("table").inner_html }
              end
            end
          end

          private

          def label
            @label ||= node.at_css(".sts-caption-label")&.content
          end

          def caption
            @caption ||= node.at_css(".sts-caption-caption")&.content
          end
        end
      end
    end
  end
end

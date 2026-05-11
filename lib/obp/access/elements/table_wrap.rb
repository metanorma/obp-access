module Obp
  class Access
    class Renderer
      class Elements
        class TableWrap < Base
          def self.classes
            %w[sts-table-wrap fig-index]
          end

          def match_node?
            super && !inside_figure?
          end

          private

          def inside_figure?
            node.ancestors.any? { |a| a.classes == ["sts-fig"] }
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"table-wrap") do
                xml.label caption_label if caption_label
                if caption_text
                  xml.caption do
                    xml.title caption_text
                  end
                end
                xml.table { xml << node.at_css("table").inner_html }
              end
            end
          end

          def caption_label
            @caption_label ||= node.at_css(".sts-caption-label")&.content
          end

          def caption_text
            @caption_text ||= node.at_css(".sts-caption")&.content
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::TableWrap)

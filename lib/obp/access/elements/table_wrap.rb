module Obp
  class Access
    class Renderer
      class Elements
        class TableWrap < Base
          def self.classes
            %w[sts-table-wrap]
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
                xml.table { xml << table_markup }
              end
            end
          end

          # Serialize the children as XML so void elements (e.g. <col>)
          # self-close; inner_html emits unclosed HTML voids that swallow
          # following rows when the builder re-parses the fragment.
          def table_markup
            node.at_css("table").children.map(&:to_xml).join
          end

          def caption_label
            @caption_label ||= node.at_css(".sts-caption-label")&.content
          end

          def caption_text
            @caption_text ||= node.at_css(".sts-caption-title")&.content ||
              node.at_css(".sts-caption")&.content
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::TableWrap)

module Obp
  class Access
    class Renderer
      class Elements
        class Figure < Base
          def self.classes
            %w[sts-fig]
          end

          def match_node?
            super && node.css("img").one?
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.fig do
                render_caption(xml)
                xml.graphic("xlink:href": local_image_path(node.at_css("img")))

                legend_table = node.at_css("div.sts-table-wrap.fig-index")
                render_legend(xml, legend_table) if legend_table
              end
            end
          end

          def render_caption(xml)
            caption = node.at_css(".sts-caption")
            return unless caption

            label = caption.at_css(".sts-caption-label")
            xml.label label.content if label
            title = caption.at_css(".sts-caption-title")
            xml.caption do
              xml.title title.content if title
            end
          end

          def render_legend(xml, table_node)
            xml.public_send(:"table-wrap", "content-type": "legend") do
              caption = table_node.at_css(".sts-caption")
              if caption
                xml.caption do
                  title = caption.at_css(".sts-caption-title")
                  xml.title title.content if title
                end
              end
              xml.table { xml << table_node.at_css("table").inner_html }
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Figure)

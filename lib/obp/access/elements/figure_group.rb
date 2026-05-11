module Obp
  class Access
    class Renderer
      class Elements
        class FigureGroup < Base
          def self.classes
            %w[sts-fig]
          end

          def match_node?
            super && node.css("img").count > 1
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"fig-group") do
                render_caption(xml, node)
                node.css("img").each { |img| render_figure(xml, img) }
              end
            end
          end

          def render_caption(xml, children)
            xml.label children.at(".sts-caption-label").content
            xml.caption do
              xml.title children.at(".sts-caption-title").content
            end
          end

          def render_figure(xml, img)
            xml.fig do
              div = img.previous
              xml.label div.at(".sts-caption-label").content
              xml.caption do
                xml.title div.at(".sts-caption-title").content
              end
              xml.graphic("xlink:href": local_image_path(img))
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::FigureGroup)

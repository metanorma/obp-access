# frozen_string_literal: true

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
                render_caption_from(xml, node)
                node.css("img").each { |img| render_figure(xml, img) }
              end
            end
          end

          def render_figure(xml, img)
            xml.fig do
              # OBP HTML often places no caption between grouped imgs; guard accordingly.
              render_caption_from(xml, img.previous_element) if img.previous_element
              xml.graphic("xlink:href": local_image_path(img))
            end
          end

          def render_caption_from(xml, source)
            label = source&.at(".sts-caption-label")
            title = source&.at(".sts-caption-title")
            xml.label label.content if label
            return unless title

            xml.caption do
              xml.title title.content
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::FigureGroup)

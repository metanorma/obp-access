module Obp
  module Access
    class Renderer
      class Elements
        class FigureGroup < Base
          def self.classes
            %w[sts-fig]
          end

          def match_node?
            # Figure group contains many img in the same div.sts-fig, otherwise it's a fig
            super && node.css("img").count > 1
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"fig-group") do
                render_caption(xml, node)
                node.css("img").each do |children|
                  render_figure(xml, children)
                end
              end
            end
          end

          private

          def render_caption(xml, children)
            # children.at will return the first caption, which is used for fig-group caption
            xml.label children.at(".sts-caption-label").content
            xml.caption do
              xml.title children.at(".sts-caption-title").content
            end
          end

          def render_figure(xml, img)
            xml.fig do
              div = img.previous # Find the caption related to this img
              xml.label div.at(".sts-caption-label").content
              xml.caption do
                xml.title div.at(".sts-caption-title").content
              end
              xml.graphic("xlink:href": img.attr("src"))
            end
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Renderer
      class Elements
        class Figure < Base
          def self.classes
            %w[sts-fig]
          end

          def match_node?
            # Figure contains only one img in the same div.sts-fig, otherwise it's a fig-group
            super && node.css("img").count == 1
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.fig do
                render_figure(xml, node)
              end
            end
          end

          private

          def render_figure(xml, children)
            xml.label children.at(".sts-caption-label").content
            xml.caption do
              xml.title children.at(".sts-caption-title").content
            end
            xml.graphic("xlink:href": children.at("img").attr("src"))
          end
        end
      end
    end
  end
end

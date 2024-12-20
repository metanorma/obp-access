module Obp
  module Access
    class Renderer
      class Elements
        class Figure < Base
          def self.classes
            %w[sts-fig]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.fig do
                xml.label node.at_css(".sts-caption-label").content
                xml.caption do
                  xml.title node.at_css(".sts-caption-title").content
                end
                xml.graphic("xlink:href": image) # TODO: How to render image?
              end
            end
          end

          private

          def image
            node.at_css("img").attr("src")
          end
        end
      end
    end
  end
end

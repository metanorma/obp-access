module Obp
  class Access
    class Renderer
      class Elements
        class DispFormula < Base
          def self.classes
            %w[sts-disp-formula-panel]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"disp-formula") do
                xml.label label if label
                if math
                  xml << math.to_xml
                elsif graphic_path
                  xml.graphic("xlink:href": graphic_path)
                end
              end
            end
          end

          def label
            text = node.at_css(".sts-disp-formula-label")&.text&.strip
            text unless text&.empty?
          end

          def math
            @math ||= node.at_css("math")
          end

          # OBP serves formula images from its own graphics store, which
          # Imager does not download; fall back to the original src.
          def graphic_path
            @graphic_path ||= begin
              img = node.at_css("img")
              img && (stored_image_path(img) || img.attr("src"))
            end
          end

          def stored_image_path(img)
            images = metas["images"]
            images[img.attr("src")] if images.is_a?(Hash)
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::DispFormula)

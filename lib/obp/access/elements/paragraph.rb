module Obp
  class Access
    class Renderer
      class Elements
        class Paragraph < Base
          include InlineRenderer

          def self.classes
            %w[sts-p]
          end

          def match_node?
            super && node.parent.name != "li"
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.p do
                node.children.each { |child| render_inline(xml, child) }
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Paragraph)

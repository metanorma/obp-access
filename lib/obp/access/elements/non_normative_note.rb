module Obp
  class Access
    class Renderer
      class Elements
        class NonNormativeNote < Base
          include InlineRenderer

          def self.classes
            %w[sts-non-normative-note]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"non-normative-note") do
                label_node = node.at_css(".sts-non-normative-note-label")
                xml.label label_node.text if label_node

                p_node = node.at_css("p")
                if p_node
                  xml.p do
                    p_node.children.each { |child| render_inline(xml, child) }
                  end
                end
              end
            end
          end

          def inline_type(node)
            if node.is_a?(Nokogiri::XML::Text)
              :text
            elsif node.is_a?(Nokogiri::XML::Element)
              if node.classes == ["sts-non-normative-note-label"]
                :label
              else
                super
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::NonNormativeNote)

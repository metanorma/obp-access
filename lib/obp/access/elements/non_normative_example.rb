module Obp
  class Access
    class Renderer
      class Elements
        # Renders the example label; the content div.sts-p children are
        # rendered by Paragraph when the renderer recurses into them.
        class NonNormativeExample < Base
          def self.classes
            %w[sts-non-normative-example]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"non-normative-example") do
                label_node = node.at_css(".sts-non-normative-example-label")
                xml.label label_node.text if label_node
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::NonNormativeExample)

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Note < Base
            def self.classes
              %w[sts-tbx-note]
            end

            private

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.public_send(:"tbx:note") do
                  node.children.each { |children| render_inline(xml, children) }
                end
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::Note)

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Example < Base
            def self.classes
              %w[sts-tbx-example]
            end

            private

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.public_send(:"tbx:example") do
                  node.css(".sts-tbx-example-content").children.each { |children| render_inline(xml, children) }
                end
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::Example)

module Obp
  class Access
    class Renderer
      class Elements
        class Copyright < Base
          def self.classes
            %w[sts-copyright]
          end

          private

          def insertion_target
            "front/std-meta/permissions"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"copyright-year", node.content.scan(/\d+/).first)
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Copyright)

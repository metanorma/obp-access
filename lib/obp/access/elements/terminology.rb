module Obp
  class Access
    class Renderer
      class Elements
        class Terminology < Base
          def self.classes
            %w[sts-section sts-tbx-sec]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"term-sec", id: "sec_#{id}") do
                xml.label id
                xml.public_send(:"tbx:termEntry", id: "term_#{id}") do
                  xml.public_send(:"tbx:langSet", "xml:lang": metas["language"])
                end
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology)

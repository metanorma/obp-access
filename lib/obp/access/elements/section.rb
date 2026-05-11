module Obp
  class Access
    class Renderer
      class Elements
        class Section < Base
          def self.classes
            %w[sts-section]
          end

          def match_node?
            super && id =~ /\A\d+(\.\d+)*\z/
          end

          private

          def insertion_target
            "body"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec(id: "sec_#{id}") do
                xml.label id
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Section)

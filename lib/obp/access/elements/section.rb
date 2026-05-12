# frozen_string_literal: true

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
              attrs = { id: "sec_#{id}" }
              sec_type = SectionType.for(id)
              attrs[:"sec-type"] = sec_type if sec_type
              xml.sec(**attrs) do
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

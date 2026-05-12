# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class Title < Base
          def self.classes
            %w[sts-sec-title]
          end

          private

          def insert_method
            :add_child
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.title sanitize_text(section_title.text)
            end
          end

          def section_title
            @section_title ||= SectionTitle.new(node.content)
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Title)

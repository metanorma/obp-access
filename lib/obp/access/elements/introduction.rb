module Obp
  class Access
    class Renderer
      class Elements
        class Introduction < Base
          def self.classes
            %w[sts-section]
          end

          def match_node?
            super && %w[foreword intro].include?(id)
          end

          private

          def insertion_target
            "front"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec(id: "sec_#{id}", "sec-type": id)
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Introduction)

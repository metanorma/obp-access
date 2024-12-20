module Obp
  module Access
    class Renderer
      class Elements
        class Copyright < Base
          def self.classes
            %w[sts-copyright]
          end

          def target
            "front/std-meta/permissions"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"copyright-year", node.content.scan(/\d+/).first)
            end
          end
        end
      end
    end
  end
end

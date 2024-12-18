module Obp
  module Access
    class Renderer
      class Elements
        class Terminology
          class Note < Base
            def self.classes
              %w[sts-tbx-note]
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:note") do
                  # NOTE: Can't guess <std><std-ref>
                  node.children.each do |children|
                    render_entailed_term(xml, children)
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end

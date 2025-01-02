module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Example < Base
            def self.classes
              %w[sts-tbx-example]
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:example") do
                  node.css(".sts-tbx-example-content").children.each do |children|
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

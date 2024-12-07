module Obp
  module Access
    class Rendered
      class Elements
        class Terminology
          class Definition < Base
            def self.classes
              %w[sts-tbx-def]
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:definition") do
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

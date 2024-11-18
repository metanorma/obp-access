module Obp
  module Access
    class Rendered
      class Elements
        class Terminology
          class Note < Elements::Base
            def self.classes
              %w[sts-tbx-note]
            end

            def target
              "/tbx:termEntry/tbx:langSet"
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:note") do
                  node.children.each do |children|
                    if children.classes == ["sts-tbx-entailedTerm"]
                      target = children.at_css("a").attr("href").split(":").last
                      xml.send(:"tbx:entailedTerm", children.text, target: "term_#{target}")
                    else
                      xml.text(children.content) # Do not strip content here
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
end

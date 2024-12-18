module Obp
  module Access
    class Renderer
      class Elements
        class List < Base
          def self.classes
            %w[list]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              # FIXME: How to define "list-type" attribute ("alpha-lower" or "dash")?
              xml.list("list-type": "dash") do
                # Take only first level li children
                node.xpath("./ul/li").map do |li|
                  xml.send(:"list-item") do
                    label = li.at_css("span.sts-label")
                    p = label.next

                    # FIXME: Re-use Elements classes for labels & paragraphs
                    xml.label label.content
                    xml.p p.content
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

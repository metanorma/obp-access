module Obp
  module Access
    class Converter
      class Elements
        class List < Base
          def match_node?
            node.name == "div" && node.attr("class") == "list"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              # FIXME: How to define "list-type" attribute ("alpha-lower" or "dash")?
              xml.list do
                # Get only first level li children
                node.xpath("./ul/li").map do |li|
                  xml.send(:"list-item") do
                    label = li.at_css("span.sts-label")
                    p = label.next

                    # FIXME: Re-use Elements classes for labels & paragraphs
                    xml.label label.content.strip
                    xml.p p.content.strip
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

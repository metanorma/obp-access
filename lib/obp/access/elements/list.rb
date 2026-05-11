module Obp
  class Access
    class Renderer
      class Elements
        class List < Base
          include InlineRenderer

          def self.classes
            %w[list]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.list("list-type": "dash") do
                node.xpath("./ul/li").each do |li|
                  xml.public_send(:"list-item") do
                    render_li(xml, li)
                  end
                end
              end
            end
          end

          def render_li(xml, item)
            render_li_label(xml, item)
            render_li_paragraph(xml, item)
            render_nested_list(xml, item)
          end

          def render_li_label(xml, item)
            label = item.at_css("span.sts-label")
            xml.label label.text if label
          end

          def render_li_paragraph(xml, item)
            p_node = item.at_css(".sts-p")
            return unless p_node

            xml.p { p_node.children.each { |c| render_inline(xml, c) } }
          end

          def render_nested_list(xml, item)
            nested = item.at_css(".list")
            return unless nested

            nested.xpath("./ul/li").each do |nested_item|
              xml.public_send(:"list-item") { render_li(xml, nested_item) }
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::List)

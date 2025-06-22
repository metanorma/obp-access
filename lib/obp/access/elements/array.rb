module Obp
  class Access
    class Renderer
      class Elements
        class Array < Base
          def self.classes
            %w[sts-array]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.array do
                xml.table do
                  render_colgroup(xml, node)
                  render_thead(xml, node)
                  render_tbody(xml, node)
                end
              end
            end
          end

          private

          def render_colgroup(xml, node)
            nodes = node.css("colgroup col")
            return if nodes.empty?

            xml.colgroup do
              nodes.each do |col|
                xml.col col.attributes.slice("align", "width")
              end
            end
          end

          def render_thead(xml, node)
            nodes = node.css("thead tr")
            return if nodes.empty?

            xml.thead do
              nodes.each do |tr|
                xml.tr do
                  tr.css("th").each do |th|
                    xml.th sanitize_text(th.content)
                  end
                end
              end
            end
          end

          def render_tbody(xml, node)
            nodes = node.css("tbody tr")
            return if nodes.empty?

            xml.tbody do
              nodes.each do |tr|
                xml.tr do
                  tr.css("td").each do |td|
                    xml.td sanitize_text(td.content)
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

module Obp
  class Access
    class Renderer
      class Elements
        class Array < Base
          def self.classes
            %w[sts-array]
          end

          private

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.array do
                xml.table do
                  render_colgroup(xml)
                  render_thead(xml)
                  render_tbody(xml)
                end
              end
            end
          end

          def render_colgroup(xml)
            cols = node.css("colgroup col")
            return if cols.empty?

            xml.colgroup do
              cols.each { |col| xml.col col.attributes.slice("align", "width") }
            end
          end

          def render_thead(xml)
            rows = node.css("thead tr")
            return if rows.empty?

            xml.thead do
              rows.each do |tr|
                xml.tr do
                  tr.css("th").each { |th| xml.th sanitize_text(th.content) }
                end
              end
            end
          end

          def render_tbody(xml)
            rows = node.css("tbody tr")
            return if rows.empty?

            xml.tbody do
              rows.each do |tr|
                xml.tr do
                  tr.css("td").each { |td| xml.td sanitize_text(td.content) }
                end
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Array)

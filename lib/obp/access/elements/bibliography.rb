module Obp
  class Access
    class Renderer
      class Elements
        class Bibliography < Base
          def self.classes
            %w[sts-section sts-ref-list]
          end

          private

          def insertion_target
            "back"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"ref-list", "content-type": "bibl", id: "sec_bibl") do
                node.css("tr td:last-child").each_with_index do |children, index|
                  xml.ref("content-type": "standard", id: "biblref_#{index + 1}") do
                    render_ref(xml, children)
                  end
                end
              end
            end
          end

          def render_ref(xml, children) # rubocop:disable Metrics/AbcSize
            href = children.at_css("a.sts-std-ref")
            title = children.at_css("span.sts-std-title")

            attrs = {}
            attrs["std-id"] = href.attr("href").delete("#") if href

            xml.std(attrs) do
              if href
                xml.public_send(:"std-ref", href.content)
                text = children.children[2] ? children.children[1].content : children.children[0].content
                title_text = children.children[2] ? children.children[2].content : children.children[1].content
                xml << text
                xml.title title_text
              elsif title
                xml.public_send(:"std-ref", children.children[0].content)
                xml.title children.children[1].content
              else
                xml << children.inner_html
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Bibliography)

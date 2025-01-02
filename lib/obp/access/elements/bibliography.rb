# HTML:
# <tr>
#     <td class="sts-label">
#         <a id="iso_std_iso_34000_ed-1_v1_en_ref_1" name="iso:std:iso:34000:ed-1:v1:en:ref:1"/>
#         <span class="sts-label">[1]</span>
#     </td>
#     <td>
#         <a class="sts-std-ref" href="#iso:std:iso:8601:-1:ed-1:en">ISO 8601-1:2019</a>
#         ,
#         <span class="sts-std-title">
#           Date and time — Representations for information interchange — Part 1: Basic rules
#         </span>
#     </td>
# </tr>
# STS:
# <ref content-type="standard" id="biblref_1">
#   <std std-id="iso:std:iso:8601:-1">
#     <std-ref>ISO 8601-1:2019</std-ref>
#     ,
#     <title>Date and time — Representations for information interchange — Part 1: Basic rules</title>
#   </std>
# </ref>
module Obp
  class Access
    class Renderer
      class Elements
        class Bibliography < Base
          def self.classes
            %w[sts-section sts-ref-list]
          end

          def target
            "back"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"ref-list", "content-type": "bibl", id: "sec_bibl") do
                node.css("tr td:last-child").each_with_index do |children, index|
                  xml.ref("content-type": "standard", id: "biblref_#{index + 1}") do
                    render_ref(xml, children)
                  end
                end
              end
            end
          end

          private

          def render_ref(xml, children) # rubocop:disable Metrics/AbcSize
            attrs = {}
            href = children.at_css("a.sts-std-ref")
            title = children.at_css("span.sts-std-title")
            attrs["std-id"] = href.attr("href").delete("#") if href

            xml.std(attrs) do
              if href
                xml.send(:"std-ref", href.content)
                text = children.children[2] ? children.children[1].content : children.children[0].content
                title = children.children[2] ? children.children[2].content : children.children[1].content
                xml << text
                xml.title title
              elsif title
                xml.send(:"std-ref", children.children[0].content)
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

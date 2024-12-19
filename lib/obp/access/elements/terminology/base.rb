module Obp
  module Access
    class Renderer
      class Elements
        class Terminology
          class Base < Elements::Base
            def self.classes; end

            def path_suffix
              "/tbx:termEntry/tbx:langSet"
            end

            private

            def render_entailed_term(xml, children)
              if children.classes == ["sts-tbx-entailedTerm"]
                target = children.at_css("a").attr("href").split(":").last
                xml.send(:"tbx:entailedTerm", target: "term_#{target}") do
                  xml << sanitize_text(children.text)
                end
              else
                xml.text(children.content)
              end
            end

            def tbx_category(node)
              content = node.inner_html
              type = "noun"

              if content.end_with?("<b>verb</b>")
                content = node.inner_html.gsub("<b>verb</b>", "").gsub("<b>,</b>", "")
                type = "verb"
              end

              [sanitize_text(content), type]
            end
          end
        end
      end
    end
  end
end

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigDeprecated < Tig
            def self.classes
              %w[sts-tbx-term deprecatedTerm]
            end

            private

            def normative_authorization
              "deprecatedTerm"
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.public_send(:"tbx:tig", id: "term_#{id}-#{index}") do
                  render_tig_content(xml)
                end
              end
            end

            def parsed_html
              strip_deprecation_label(node.inner_html)
            end

            def strip_deprecation_label(html)
              html.gsub(%r{<span class="sts-tbx-term-depr-label">.*?</span>}, "")
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::TigDeprecated)

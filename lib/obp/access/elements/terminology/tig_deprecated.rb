# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigDeprecated < Tig
            NORMATIVE_AUTHORIZATION = "deprecatedTerm"

            def self.classes
              %w[sts-tbx-term deprecatedTerm]
            end

            private

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

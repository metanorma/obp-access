module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Base < Elements::Base
            include InlineRenderer

            def self.classes
              nil
            end

            private

            def path_suffix
              "/tbx:termEntry/tbx:langSet"
            end

            def bold_term?(node)
              node.inner_html.start_with?("<b>") || node.inner_html.include?("<b>")
            end
          end
        end
      end
    end
  end
end

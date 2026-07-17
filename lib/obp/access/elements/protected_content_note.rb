module Obp
  class Access
    class Renderer
      class Elements
        # OBP replaces paywalled sections with this placeholder ("Only
        # informative sections of standards are publicly available...").
        # Skip it explicitly: render nothing and halt recursion, so the
        # placeholder text never leaks into the output.
        class ProtectedContentNote < Base
          def self.classes
            %w[sts-protected-content-note]
          end

          # Accepts (and ignores) the render target; the nil return tells
          # the renderer to halt recursion into this subtree.
          def render(*)
            nil
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::ProtectedContentNote)

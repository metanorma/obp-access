module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigPreferred < Tig
            def self.classes
              %w[sts-tbx-term preferredTerm]
            end

            private

            def normative_authorization
              "preferredTerm"
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::TigPreferred)

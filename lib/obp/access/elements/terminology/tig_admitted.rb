module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigAdmitted < Tig
            def self.classes
              %w[sts-tbx-term admittedTerm]
            end

            private

            def normative_authorization
              "admittedTerm"
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::TigAdmitted)

# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigAdmitted < Tig
            NORMATIVE_AUTHORIZATION = "admittedTerm"

            def self.classes
              %w[sts-tbx-term admittedTerm]
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::TigAdmitted)

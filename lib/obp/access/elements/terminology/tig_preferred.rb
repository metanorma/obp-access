# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class TigPreferred < Tig
            NORMATIVE_AUTHORIZATION = "preferredTerm"

            def self.classes
              %w[sts-tbx-term preferredTerm]
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::TigPreferred)

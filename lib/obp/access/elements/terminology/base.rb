# frozen_string_literal: true

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
          end
        end
      end
    end
  end
end

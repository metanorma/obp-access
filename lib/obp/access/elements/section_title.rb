# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class SectionTitle
          LABEL_PATTERN = /\A(\d+(?:\.\d+)*)\s{2,}/

          attr_reader :label, :text

          def initialize(raw_text)
            match = raw_text.match(LABEL_PATTERN)
            if match
              @label = match[1]
              @text = raw_text[match[0].length..].strip
            else
              @label = nil
              @text = raw_text.strip
            end
          end
        end
      end
    end
  end
end

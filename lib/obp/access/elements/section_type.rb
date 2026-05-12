# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class SectionType
          FIXED_TYPES = {
            "1" => "scope",
            "2" => "norm-refs",
          }.freeze

          def self.for(id)
            FIXED_TYPES[id] || infer_from_pattern(id)
          end

          def self.infer_from_pattern(id)
            return "terms" if id.match?(/\A\d+\.\d*\z/)
            return "terms" if id.match?(/\A\d+\z/) && id.to_i >= 3

            nil
          end
        end
      end
    end
  end
end

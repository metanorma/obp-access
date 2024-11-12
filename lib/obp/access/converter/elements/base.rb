module Obp
  module Access
    class Converter
      class Elements
        class Base
          attr_reader :node

          def initialize(node:)
            @node = node
          end

          def id
            @id ||= node.attr("id").split("_").last
          end

          def match_node?
            raise NotImplementedError
          end

          def target
            raise NotImplementedError
          end
        end
      end
    end
  end
end

module Obp
  module Access
    class Converter
      class Elements
        class Base
          attr_reader :node

          def initialize(node:)
            @node = node
          end

          def render
            content.doc.root.to_xml
          end

          def match_node?
            raise NotImplementedError
          end

          def content
            raise NotImplementedError
          end
        end
      end
    end
  end
end

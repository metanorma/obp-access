module Obp
  module Access
    class Rendered
      class Elements
        class Base
          attr_reader :document, :node

          def initialize(document:, node:)
            @document = document
            @node = node
          end

          def id
            @id ||= node.attr("id").split("_").last
          end

          def to_xml
            content.doc.root.to_xml
          end

          def render(target:)
            # We can force document target using Element#target method
            document.at(target || self.target).add_child(to_xml)
          end

          def match_node?
            node.matches?(self.class.selector)
          end

          def content
            raise NotImplementedError
          end
        end
      end
    end
  end
end

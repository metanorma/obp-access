module Obp
  module Access
    class Converter
      class Sections
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
            document.at(target || self.target).add_child(to_xml)
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

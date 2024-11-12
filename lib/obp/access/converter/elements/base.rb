module Obp
  module Access
    class Converter
      class Elements
        class Base
          attr_reader :doc, :node

          def initialize(doc:, node:)
            @doc = doc
            @node = node
          end

          def id
            @id ||= node.attr("id").split("_").last
          end

          def to_xml
            content.doc.root.to_xml
          end

          def render
            doc.at(target).add_child(to_xml)
          end

          def match_node?
            raise NotImplementedError
          end

          def target
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

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

          def match_node?
            node.classes == self.class.classes
          end

          def render(target:)
            target = self.target if defined?(self.target) # We can force document target using Element#target method
            target = "#{target}#{path_suffix}" if defined?(path_suffix)
            document.at(target).add_child(to_xml)
          end

          private

          def id
            @id ||= node.attr("id").split("_").last
          end

          def to_xml
            content.doc.root.to_xml
          end

          def content
            raise NotImplementedError
          end

          def sanitize_text(text)
            text
              .gsub(/[[:space:]]+/, " ") # Remove duplicated spaces
              .gsub("<b>", "<bold>").gsub("</b>", "</bold>")
              .gsub("<i>", "<italic>").gsub("</i>", "</italic>")
          end
        end
      end
    end
  end
end

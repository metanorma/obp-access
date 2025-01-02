module Obp
  class Access
    class Renderer
      class Elements
        class Base
          # Elements are rendered using the NISO STS spec here: https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-2-html/index.html
          attr_reader :document, :metas, :node

          def initialize(document:, metas:, node:)
            @document = document
            @metas = metas
            @node = node
          end

          def match_node?
            node.classes == self.class.classes
          end

          def render(target:)
            target = self.target if defined?(self.target) # We can force document target using Element#target method
            target = "#{target}#{path_suffix}" if defined?(path_suffix)
            document.at(target).send(insert_using, to_xml)
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

          def insert_using
            :add_child # By default, child node is appended to the XML. Can force prepended per node
          end

          def sanitize_text(text)
            text
              .gsub("<b>", "<bold>").gsub("</b>", "</bold>")
              .gsub("<i>", "<italic>").gsub("</i>", "</italic>")
          end

          def local_image_path(img)
            key = img.attr("src")
            metas["images"][key]
          end
        end
      end
    end
  end
end

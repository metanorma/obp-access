module Obp
  class Access
    class Renderer
      class Elements
        class Base
          # Elements are rendered using the NISO STS spec:
          # https://www.niso-sts.org/TagLibrary/niso-sts-TL-1-2-html/index.html
          attr_reader :document, :metas, :node

          def initialize(document:, metas:, node:)
            @document = document
            @metas = metas
            @node = node
          end

          def self.classes
            nil
          end

          # Subset match: OBP varies class order and adds marker classes
          # (e.g. "commentable"), so a node matches when it carries at
          # least the registered classes, regardless of order or extras.
          def match_node?
            (self.class.classes - node.classes).empty?
          end

          def render(target:)
            effective_target = insertion_target || target
            effective_target = "#{effective_target}#{path_suffix}" if path_suffix
            document.at(effective_target).public_send(insert_method, to_xml)
          end

          private

          def insertion_target
            nil
          end

          def path_suffix
            nil
          end

          def insert_method
            :add_child
          end

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
              .gsub("<b>", "<bold>").gsub("</b>", "</bold>")
              .gsub("<i>", "<italic>").gsub("</i>", "</italic>")
          end

          def local_image_path(img)
            metas["images"][img.attr("src")]
          end
        end
      end
    end
  end
end

module Obp
  class Access
    class Renderer
      attr_reader :urn, :metas, :nodes, :document

      def initialize(urn:, metas:, nodes:)
        @urn = urn
        @metas = metas
        @nodes = nodes
        @document = Elements::Root.new(urn:, metas:).to_document
      end

      def to_xml
        @nodes.each { |node| render(node:) }
        @document.to_xml
      end

      private

      def render(node:, target: nil)
        return unless css_classes_match?(node)

        ElementRegistry.elements.each do |element_class|
          element = element_class.new(document:, metas:, node:)
          next unless element.match_node?

          xml = element.render(target:)
          section_path = xml.first.path

          node.children.each do |child|
            render(node: child, target: section_path)
          end

          xml
        end
      end

      def css_classes_match?(node)
        ElementRegistry.css_classes.any?(node.classes)
      end
    end
  end
end

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

        element = matching_element(node)
        # A nil xml means the element rendered nothing (e.g. an explicit
        # skip element); recursion into its children halts with it.
        xml = element&.render(target:)
        render_children(node, xml) if xml
      end

      def render_children(node, xml)
        section_path = xml.first&.path
        return unless section_path

        node.children.each do |child|
          render(node: child, target: section_path)
        end
      end

      # First match wins: the matching element with the most registered
      # classes is the most specific (e.g. Terminology beats Section for
      # "sts-section sts-tbx-sec"); ties resolve in registration order
      # because max_by keeps the first maximum.
      def matching_element(node)
        ElementRegistry.elements.filter_map do |element_class|
          element = element_class.new(document:, metas:, node:)
          element if element.match_node?
        end.max_by { |element| element.class.classes.size }
      end

      def css_classes_match?(node)
        ElementRegistry.css_classes.intersect?(node.classes)
      end
    end
  end
end

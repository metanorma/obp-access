require_relative "elements/base"
require_relative "elements/root"
require_relative "elements/introduction"
require_relative "elements/section"
require_relative "elements/list"
require_relative "elements/title"
require_relative "elements/paragraph"
require_relative "elements/terminology"
require_relative "elements/terminology/definition"
require_relative "elements/terminology/note"
require_relative "elements/terminology/tig"

module Obp
  module Access
    class Rendered
      attr_reader :urn, :nodes, :document

      def initialize(urn:, nodes:)
        @urn = urn
        @nodes = nodes
        @document = Elements::Root.new(urn:).to_document
      end

      def to_xml
        nodes.map { |node| render(node:) }
        document.root.to_xml
      end

      private

      def render(node:, target: nil)
        return unless css_classes_match?(node)

        elements.map do |descendant|
          element = descendant.new(document:, node:)
          next unless element.match_node?

          xml = element.render(target:)
          section_path = xml.first.path

          node.children.each do |children_node|
            render(node: children_node, target: section_path)
          end

          xml
        end
      end

      def elements
        # Only Elements::Root isn't based on Elements::Base
        @elements ||= ObjectSpace.each_object(Class).select { |klass| klass < Elements::Base }
      end

      def classes
        @classes ||= elements.map(&:classes)
      end

      def css_classes_match?(node)
        classes.any?(node.classes)
      end
    end
  end
end

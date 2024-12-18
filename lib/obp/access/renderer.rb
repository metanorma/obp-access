require_relative "elements/base"
require_relative "elements/root"
require_relative "elements/introduction"
require_relative "elements/section"
require_relative "elements/list"
require_relative "elements/title"
require_relative "elements/paragraph"
require_relative "elements/copyright"
require_relative "elements/bibliography"
require_relative "elements/terminology"
require_relative "elements/terminology/base"
require_relative "elements/terminology/definition"
require_relative "elements/terminology/note"
require_relative "elements/terminology/tig"
require_relative "elements/terminology/tig_admitted"
require_relative "elements/terminology/example"
require_relative "elements/terminology/source"

module Obp
  module Access
    class Renderer
      attr_reader :urn, :metas, :nodes, :document

      def initialize(urn:, metas:, nodes:)
        @urn = urn
        @metas = metas
        @nodes = nodes
        @document = Elements::Root.new(urn:, metas:).to_document
      end

      def to_xml
        nodes.map { |node| render(node:) }
        document.to_xml
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
        @classes ||= elements.filter_map(&:classes).uniq
      end

      def css_classes_match?(node)
        classes.any?(node.classes)
      end
    end
  end
end

require_relative "sections/base"
require_relative "sections/root"
require_relative "sections/introduction"
require_relative "sections/section"

require_relative "elements/base"
require_relative "elements/list"
require_relative "elements/title"
require_relative "elements/paragraph"

module Obp
  module Access
    class Converter
      def self.sections
        ObjectSpace.each_object(Class).select { |klass| klass < Sections::Base }
      end

      def self.elements
        ObjectSpace.each_object(Class).select { |klass| klass < Elements::Base }
      end

      def self.render_sections(document:, node:, target: nil)
        Converter.sections.map do |descendant|
          section = descendant.new(document:, node:)
          next unless section.match_node?

          xml = section.render(target:)
          section_path = xml.first.path

          node.search("div.sts-section.sts-tbx-sec").map do |children_node|
            Converter.render_sections(document:, node: children_node, target: section_path)
          end

          xml
        end
      end

      def self.render_elements(node:, xml:)
        node.traverse do |children_node|
          Converter.elements.each do |descendant|
            element = descendant.new(node: children_node)
            next unless element.match_node?

            xml << element.render
          end
        end
      end
    end
  end
end

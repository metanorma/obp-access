# frozen_string_literal: true

require "nokogiri"
require "yaml"

module Obp
  class Access
    # Maps the table-carrying nodes of an OBP preview HTML fragment —
    # div.sts-table-wrap and div.sts-array, in document order — to a
    # generic table model built from plain hashes, arrays and strings,
    # ready for YAML serialization. This is an additive read of the same
    # HTML source the Converter renders to STS XML; TableTermExtractor
    # consumes this model.
    class TableMapper
      # Both wrapper kinds carry a single <table>.
      WRAP_SELECTOR = "div.sts-table-wrap, div.sts-array"

      # Section ids look like "toc_iso_std_iso_80000-12_ed-2_v2_en_sec_3";
      # the clause key is whatever follows "_sec_" ("3", "1.1", "index").
      SECTION_ID_PATTERN = /_sec_(.+)\z/

      attr_reader :source

      def initialize(source:)
        @source = source
      end

      def tables
        @tables ||= wraps.map { |node| map_table(node) }
      end

      def to_yaml
        tables.to_yaml
      end

      private

      def document
        @document ||= Nokogiri::HTML(source.gsub(/[[:space:]]/, " "))
      end

      def wraps
        @wraps ||= begin
          nodes = document.css("body > div.sts-standard").css(WRAP_SELECTOR)
          nodes.each { |node| node.css(".sts-unknown-element").each(&:remove) }
          nodes
        end
      end

      def map_table(node)
        {
          "id" => node["id"],
          "section" => section_of(node),
          "label" => text_of(node.at_css(".sts-caption-label")),
          "caption" => caption_of(node),
          "header" => map_rows(node.css("thead tr")),
          "rows" => map_rows(body_rows(node)),
        }.compact
      end

      def section_of(node)
        section = node.ancestors("div").find do |ancestor|
          ancestor.classes.include?("sts-section")
        end
        section&.[]("id")&.[](SECTION_ID_PATTERN, 1)
      end

      def caption_of(node)
        text_of(node.at_css(".sts-caption-title")) ||
          text_of(node.at_css(".sts-caption"))
      end

      # Body rows come from <tbody> when the source splits head/body;
      # otherwise every <tr> outside a <thead> is a body row.
      def body_rows(node)
        rows = node.css("tbody tr")
        return rows unless rows.empty?

        node.css("table tr").reject { |tr| tr.ancestors("thead").any? }
      end

      def map_rows(rows)
        rows.map do |tr|
          tr.element_children.map { |cell| map_cell(cell) }
        end.reject(&:empty?)
      end

      def map_cell(cell)
        mapped = { "text" => cell_text(cell) }
        %w[colspan rowspan].each do |attribute|
          span = cell[attribute].to_i
          mapped[attribute] = span if span > 1
        end
        mapped
      end

      # Plain stripped cell text. OBP's unknown-element placeholders are
      # removed at the wrapper level; <br> and block-level div.sts-p
      # boundaries become spaces so multi-paragraph cells do not glue
      # words together.
      def cell_text(cell)
        copy = cell.dup
        copy.css("br, div.sts-p").each do |node|
          node.add_previous_sibling(" ")
        end
        copy.content.gsub(/[[:space:]]+/, " ").strip
      end

      def text_of(node)
        return unless node

        text = node.content.gsub(/[[:space:]]+/, " ").strip
        text unless text.empty?
      end
    end
  end
end

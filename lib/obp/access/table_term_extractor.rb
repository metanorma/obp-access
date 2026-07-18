# frozen_string_literal: true

require "yaml"

module Obp
  class Access
    # Extracts term entries from TableMapper's generic table model.
    #
    # Recognition rules, first match wins per table:
    #
    # 1. Quantity/item tables (the ISO 80000 family): at least 4 columns,
    #    placed in a numbered clause (the terms clause), and a majority of
    #    body rows whose first cell is an item number (e.g. "12-1.1").
    #    Column roles come from header text when possible ("Quantity
    #    Symbol", "Grandeur Symbole", ...), falling back to the ISO 80000
    #    column order [item, designation, symbol, definition, unit,
    #    remarks].
    # 2. Equivalent-terms tables: a header row naming languages in at
    #    least 2 columns; one entry per row with designations keyed by
    #    the downcased language name.
    #
    # Anything else is not a term table and yields no entries.
    class TableTermExtractor
      # "12-1.1" or "4-1"; OBP sometimes prints U+2011 NON-BREAKING
      # HYPHEN, normalized away by normalize_item.
      ITEM_PATTERN = /\A\d+-\d+(?:\.\d+)?\z/

      MIN_QUANTITY_COLUMNS = 4
      MIN_LANGUAGE_COLUMNS = 2

      # Terms clauses are numbered ("3", "3.2"); foreword, intro, bibl
      # and index sections are not.
      NUMERIC_SECTION = /\A\d+(\.\d+)*\z/

      # Checked in order against each column's joined header text; the
      # first unassigned column matching wins, so "Quantity Symbol"
      # becomes "symbol" and not "designation".
      COLUMN_ROLE_PATTERNS = [
        ["symbol", /symbol|symbole/i],
        ["definition", /definition|définition/i],
        ["unit", /unit|unité/i],
        ["remarks", /remark|remarque/i],
        ["item", /item\s+no|n[°º]|numéro|no\./i],
        ["designation", /quantity|grandeur|term|terme|name|nom/i],
      ].freeze

      # Fallback when header-text matching cannot place item+designation.
      POSITIONAL_ROLES = %w[
        item designation symbol definition unit remarks
      ].freeze

      # Language names recognized in equivalent-terms table headers.
      LANGUAGES = %w[
        english french français francais anglais russian russe русский
        german deutsch allemand spanish español espagnol italian italiano
        italien chinese chinois japanese japonais arabic arabe portuguese
        portugais korean coréen
      ].freeze

      attr_reader :tables

      def initialize(tables:)
        @tables = tables
      end

      def entries
        @entries ||= tables.flat_map { |table| table_entries(table) }
      end

      def to_yaml
        entries.to_yaml
      end

      private

      def table_entries(table)
        if quantity_table?(table)
          quantity_entries(table)
        elsif equivalent_terms_table?(table)
          equivalent_entries(table)
        else
          []
        end
      end

      def quantity_table?(table)
        return false unless NUMERIC_SECTION.match?(table["section"].to_s)
        return false unless column_count(table) >= MIN_QUANTITY_COLUMNS

        rows = table["rows"]
        return false if rows.empty?

        rows.count { |row| item_number?(cell_text(row, 0)) } * 2 > rows.size
      end

      def quantity_entries(table)
        roles = column_roles(table)
        seen = {}
        table["rows"].filter_map do |row|
          id = normalize_item(cell_text(row, roles["item"]))
          next unless ITEM_PATTERN.match?(id)
          next if seen[id]

          seen[id] = true
          quantity_entry(table, row, roles, id)
        end
      end

      def quantity_entry(table, row, roles, id)
        entry = { "id" => id,
                  "designation" => cell_text(row, roles["designation"]).to_s }
        %w[definition symbol unit remarks].each do |role|
          text = cell_text(row, roles[role])
          entry[role] = text unless text.nil? || text.empty?
        end
        entry["source"] = source_of(table)
        entry
      end

      def equivalent_terms_table?(table)
        !language_header_row(table).nil?
      end

      def equivalent_entries(table)
        languages = language_columns(language_header_row(table))
        seen = {}
        table["rows"].each_with_index.filter_map do |row, index|
          entry = equivalent_entry(table, row, languages, index)
          next if entry.nil? || seen[entry["id"]]

          seen[entry["id"]] = true
          entry
        end
      end

      def equivalent_entry(table, row, languages, index)
        designations = languages.each_with_object({}) do |(column, lang), hash|
          text = cell_text(row, column)
          hash[lang] = text unless text.nil? || text.empty?
        end
        # Rows with a single designation are letter dividers ("A", "B",
        # ...), not equivalences.
        return if designations.size < 2

        { "id" => entry_id(row, index),
          "designations" => designations,
          "source" => source_of(table) }
      end

      def entry_id(row, index)
        first = normalize_item(cell_text(row, 0))
        ITEM_PATTERN.match?(first) ? first : (index + 1).to_s
      end

      def language_header_row(table)
        table["header"].find do |row|
          row.count { |cell| language?(cell["text"]) } >= MIN_LANGUAGE_COLUMNS
        end
      end

      def language_columns(header_row)
        columns = {}
        position = 0
        header_row.each do |cell|
          columns[position] = cell["text"].downcase if language?(cell["text"])
          position += cell["colspan"] || 1
        end
        columns
      end

      def language?(text)
        LANGUAGES.include?(text.to_s.downcase)
      end

      # First unassigned column matching each role pattern wins; matched
      # columns are blanked so later roles cannot claim them again.
      def column_roles(table)
        headers = column_header_texts(table)
        roles = {}
        COLUMN_ROLE_PATTERNS.each do |role, pattern|
          column = headers.index { |text| text.match?(pattern) }
          next unless column

          headers[column] = ""
          roles[role] = column
        end
        return roles if roles["item"] && roles["designation"]

        positional_roles(table)
      end

      def positional_roles(table)
        POSITIONAL_ROLES.first(column_count(table)).each_with_index.to_h
      end

      # Each column's header text joined across header rows, colspans
      # repeated ("Quantity" + "Symbol" => "Quantity Symbol").
      def column_header_texts(table)
        grid = table["header"].map { |row| expand_row(row) }
        (0...grid_width(grid)).map do |column|
          grid.filter_map { |row| row[column] }.reject(&:empty?).join(" ")
        end
      end

      def grid_width(grid)
        grid.map(&:size).max || 0
      end

      def expand_row(row)
        row.flat_map { |cell| [cell["text"]] * (cell["colspan"] || 1) }
      end

      def column_count(table)
        (table["header"] + table["rows"])
          .map { |row| row.sum { |cell| cell["colspan"] || 1 } }.max || 0
      end

      def cell_text(row, column)
        return if column.nil?

        cell_at(row, column)&.fetch("text")
      end

      def cell_at(row, column)
        position = 0
        row.each do |cell|
          span = cell["colspan"] || 1
          return cell if column >= position && column < position + span

          position += span
        end
        nil
      end

      def item_number?(text)
        ITEM_PATTERN.match?(normalize_item(text))
      end

      def normalize_item(text)
        text.to_s.tr("\u2011", "-")
      end

      def source_of(table)
        { "table" => table["id"], "section" => table["section"] }.compact
      end
    end
  end
end

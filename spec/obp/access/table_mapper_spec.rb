# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::TableMapper do
  def tables_for(html)
    described_class.new(source: html).tables
  end

  def wrap_fragment(inner_html, section_id: "3")
    <<~HTML
      <div class="sts-standard">
        <div class="sts-section" id="toc_x_sec_#{section_id}">
          #{inner_html}
        </div>
      </div>
    HTML
  end

  def table_wrap(table_html, caption: nil, id: "tab_1")
    %(<div class="sts-table-wrap" id="#{id}">#{caption}#{table_html}</div>)
  end

  def bare_table(*cells)
    cells_html = cells.map { |cell| "<td>#{cell}</td>" }.join
    "<table><tbody><tr>#{cells_html}</tr></tbody></table>"
  end

  let(:caption) do
    '<div class="sts-caption"><span class="sts-caption-label">Table 1</span> ' \
      '<span class="sts-caption-title">Quantities and units</span></div>'
  end

  describe "#tables" do
    it "maps a table wrap to a generic model" do
      table = <<~HTML
        <table>
          <thead><tr>
            <th>Item No.</th><th colspan="3">Quantity</th><th>Unit</th>
          </tr></thead>
          <tbody><tr>
            <td>12-1.1</td><td>lattice vector</td><td>R</td>
            <td>definition</td><td>m</td>
          </tr></tbody>
        </table>
      HTML
      expected = [
        { "id" => "tab_1", "section" => "3", "label" => "Table 1",
          "caption" => "Quantities and units",
          "header" => [
            [{ "text" => "Item No." }, { "text" => "Quantity", "colspan" => 3 },
             { "text" => "Unit" }],
          ],
          "rows" => [
            [{ "text" => "12-1.1" }, { "text" => "lattice vector" },
             { "text" => "R" }, { "text" => "definition" }, { "text" => "m" }],
          ] },
      ]

      html = wrap_fragment(table_wrap(table, caption: caption))
      expect(tables_for(html)).to eq(expected)
    end

    it "represents rowspan and omits spans of 1" do
      table = <<~HTML
        <table><thead>
          <tr><th rowspan="2" colspan="1">Item No.</th><th>Quantity</th></tr>
          <tr><th>Name</th></tr>
        </thead></table>
      HTML
      expected = [
        [{ "text" => "Item No.", "rowspan" => 2 }, { "text" => "Quantity" }],
        [{ "text" => "Name" }],
      ]

      tables = tables_for(wrap_fragment(table_wrap(table)))
      expect(tables.first["header"]).to eq(expected)
    end

    it "keeps the raw section suffix for non-numeric clauses" do
      tables = tables_for(wrap_fragment(table_wrap(bare_table("a")),
                                        section_id: "index"))

      expect(tables.first["section"]).to eq("index")
    end

    it "derives dotted subsection numbers" do
      tables = tables_for(wrap_fragment(table_wrap(bare_table("a")),
                                        section_id: "1.1"))

      expect(tables.first["section"]).to eq("1.1")
    end

    it "omits id and section when the wrap carries neither" do
      html = '<div class="sts-standard"><div class="sts-table-wrap">' \
             "<table><tbody><tr><td>a</td></tr></tbody></table></div></div>"

      expect(tables_for(html)).to eq(
        [{ "header" => [], "rows" => [[{ "text" => "a" }]] }],
      )
    end

    it "falls back to the sts-caption text without a caption title" do
      caption = '<div class="sts-caption">Table without title</div>'
      html = wrap_fragment(table_wrap(bare_table("a"), caption: caption))

      expect(tables_for(html).first["caption"]).to eq("Table without title")
    end

    it "maps sts-array wrappers like table wraps" do
      html = <<~HTML
        <div class="sts-standard"><div class="sts-section" id="toc_x_sec_1.1">
          <div class="sts-array">
            <table><thead><tr><th>English</th><th>Francais</th></tr></thead>
            <tbody><tr><td>fire</td><td>feu</td></tr></tbody></table>
          </div>
        </div></div>
      HTML
      expected = [
        { "section" => "1.1",
          "header" => [[{ "text" => "English" }, { "text" => "Francais" }]],
          "rows" => [[{ "text" => "fire" }, { "text" => "feu" }]] },
      ]

      expect(tables_for(html)).to eq(expected)
    end

    it "strips sts-unknown-element placeholders from cells" do
      unknown = '<span class="sts-unknown-element">' \
                "[no rendering defined for element: std-ref]</span>"
      cell = "#{unknown}visible"
      tables = tables_for(wrap_fragment(table_wrap(bare_table(cell))))

      expect(tables.first["rows"]).to eq([[{ "text" => "visible" }]])
    end

    it "maps rows of a table without thead/tbody split" do
      table = "<table><tr><td>a</td><td>b</td></tr></table>"
      html = wrap_fragment(table_wrap(table))

      expect(tables_for(html).first).to include(
        "header" => [], "rows" => [[{ "text" => "a" }, { "text" => "b" }]],
      )
    end

    it "preserves th cells in tbody rows" do
      table = "<table><tbody><tr><th>heading</th><td>value</td></tr></tbody>" \
              "</table>"

      tables = tables_for(wrap_fragment(table_wrap(table)))

      expect(tables.first["rows"]).to eq(
        [[{ "text" => "heading" }, { "text" => "value" }]],
      )
    end

    it "separates paragraphs and line breaks with spaces" do
      table = <<~HTML
        <table><tbody><tr>
          <td>atomic number,<div class="sts-p">proton number</div></td>
          <td>kg<div class="sts-p">u</div></td>
          <td>one<br>two</td>
        </tr></tbody></table>
      HTML
      expected = [
        [{ "text" => "atomic number, proton number" }, { "text" => "kg u" },
         { "text" => "one two" }],
      ]

      tables = tables_for(wrap_fragment(table_wrap(table)))
      expect(tables.first["rows"]).to eq(expected)
    end

    it "returns no tables without a sts-standard root" do
      expect(tables_for("<div>nothing</div>")).to eq([])
    end
  end

  describe "#to_yaml" do
    it "serializes an empty array for table-less documents" do
      mapper = described_class.new(source: "<div>nothing</div>")

      expect(mapper.to_yaml).to eq("--- []\n")
    end
  end

  describe "ISO 80000-12 fixture" do
    let(:fixture) do
      File.expand_path("../../../../iso-iec-80000/reference-docs/en/html" \
                       "/ISO-80000-12-E.html", __dir__)
    end

    it "maps both tables in document order" do
      skip "Fixture not available" unless File.exist?(fixture)

      tables = tables_for(File.read(fixture))

      expect(tables.size).to eq(2)
      expect(tables.first).to include(
        "id" => "iso_std_iso_80000-12_ed-2_v2_en_tab_1", "section" => "3",
        "label" => "Table 1"
      )
      expect(tables.last).to include("section" => "index")
    end

    it "maps the quantities table header and first row faithfully" do
      skip "Fixture not available" unless File.exist?(fixture)

      table = tables_for(File.read(fixture)).first

      expected_header = [
        [{ "text" => "Item No." }, { "text" => "Quantity", "colspan" => 3 },
         { "text" => "Unit" }, { "text" => "Remarks" }],
        [{ "text" => "" }, { "text" => "Name" }, { "text" => "Symbol" },
         { "text" => "Definition" }, { "text" => "" }, { "text" => "" }],
      ]
      expected_row = [
        { "text" => "12-1.1" }, { "text" => "lattice vector" },
        { "text" => "R" },
        { "text" => "translation vector that maps the crystal lattice " \
                    "on itself" },
        { "text" => "m" },
        { "text" => "The non-SI unit ångström (Å) is widely used by x-ray " \
                    "crystallographers and structural chemists." }
      ]
      expect(table["header"]).to eq(expected_header)
      expect(table["rows"].size).to eq(60)
      expect(table["rows"].first).to eq(expected_row)
    end
  end
end

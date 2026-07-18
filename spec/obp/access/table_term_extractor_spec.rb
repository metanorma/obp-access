# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::TableTermExtractor do
  def entries_for(tables)
    described_class.new(tables: tables).entries
  end

  def row(*texts)
    texts.map { |text| { "text" => text } }
  end

  def table(section:, header:, rows:, id: "tab_1")
    { "id" => id, "section" => section, "header" => header, "rows" => rows }
  end

  def entries_from_file(path)
    tables = Obp::Access::TableMapper.new(source: File.read(path)).tables
    entries_for(tables)
  end

  let(:en_header) do
    [
      [{ "text" => "Item No." }, { "text" => "Quantity", "colspan" => 3 },
       { "text" => "Unit" }, { "text" => "Remarks" }],
      row("", "Name", "Symbol", "Definition", "", ""),
    ]
  end

  let(:fr_header) do
    [
      [{ "text" => "N°" }, { "text" => "Grandeur", "colspan" => 3 },
       { "text" => "Unité" }, { "text" => "Remarques" }],
      row("", "Nom", "Symbole", "Définition", "", ""),
    ]
  end

  let(:quantity_rows) do
    [row("12-1.1", "lattice vector", "R", "a definition", "m", "a remark")]
  end

  let(:language_header) { [row("", "English", "Francais", "Deutsch")] }

  describe "quantity/item tables" do
    it "maps columns by header text" do
      tables = [table(section: "3", header: en_header, rows: quantity_rows)]
      expected = [
        { "id" => "12-1.1", "designation" => "lattice vector",
          "definition" => "a definition", "symbol" => "R", "unit" => "m",
          "remarks" => "a remark",
          "source" => { "table" => "tab_1", "section" => "3" } },
      ]

      expect(entries_for(tables)).to eq(expected)
    end

    it "maps French headers (N°, Grandeur, Unité, Remarques)" do
      rows = [row("12-1.1", "vecteur du réseau, m", "R",
                  "une définition", "m", "une remarque")]
      tables = [table(section: "3", header: fr_header, rows: rows)]
      expected = [
        { "id" => "12-1.1", "designation" => "vecteur du réseau, m",
          "definition" => "une définition", "symbol" => "R", "unit" => "m",
          "remarks" => "une remarque",
          "source" => { "table" => "tab_1", "section" => "3" } },
      ]

      expect(entries_for(tables)).to eq(expected)
    end

    it "falls back to positional roles without a header" do
      tables = [table(section: "3", header: [], rows: quantity_rows)]

      expect(entries_for(tables).first).to include(
        "designation" => "lattice vector", "symbol" => "R",
        "definition" => "a definition", "unit" => "m", "remarks" => "a remark"
      )
    end

    it "omits empty fields but always carries id and designation" do
      rows = [row("12-1.1", "", "", "a definition", "", "")]
      tables = [table(section: "3", header: en_header, rows: rows)]
      expected = [
        { "id" => "12-1.1", "designation" => "",
          "definition" => "a definition",
          "source" => { "table" => "tab_1", "section" => "3" } },
      ]

      expect(entries_for(tables)).to eq(expected)
    end

    it "normalizes U+2011 non-breaking hyphens in item numbers" do
      rows = [row("3‑1.1", "length", "l, L", "a definition", "m", "")]
      tables = [table(section: "3", header: en_header, rows: rows)]

      expect(entries_for(tables).first["id"]).to eq("3-1.1")
    end

    it "skips continuation rows and keeps the first of duplicated ids" do
      rows = [row("12-1.1", "lattice vector", "R", "a definition", "m", ""),
              row("", "", "", "", "", "continued remark"),
              row("12-1.1", "duplicate", "?", "duplicate", "?", ""),
              row("12-1.2", "fundamental lattice vectors", "a", "def", "m", "")]
      tables = [table(section: "3", header: en_header, rows: rows)]

      entries = entries_for(tables)

      expect(entries.map { |entry| entry["id"] }).to eq(%w[12-1.1 12-1.2])
      expect(entries.first["designation"]).to eq("lattice vector")
    end

    it "rejects quantity-shaped tables outside numbered clauses" do
      tables = [table(section: "intro", header: en_header,
                      rows: quantity_rows)]

      expect(entries_for(tables)).to eq([])
    end

    it "rejects tables with fewer than 4 columns" do
      rows = [row("12-1.1", "lattice vector", "12-1.1")]
      tables = [table(section: "3", header: [], rows: rows)]

      expect(entries_for(tables)).to eq([])
    end

    it "rejects tables where most rows lack item numbers" do
      rows = [row("12-1.1", "a", "b", "c", "d", "e"),
              row("note", "a", "b", "c", "d", "e"),
              row("note", "a", "b", "c", "d", "e")]
      tables = [table(section: "3", header: en_header, rows: rows)]

      expect(entries_for(tables)).to eq([])
    end
  end

  describe "equivalent-terms tables" do
    it "extracts designations keyed by downcased language" do
      rows = [row("1", "absorption, atmospheric", "absorption atmosphérique",
                  "atmosphärische Absorption")]
      tables = [table(section: "1.1", header: language_header, rows: rows)]
      expected = [
        { "id" => "1",
          "designations" => { "english" => "absorption, atmospheric",
                              "francais" => "absorption atmosphérique",
                              "deutsch" => "atmosphärische Absorption" },
          "source" => { "table" => "tab_1", "section" => "1.1" } },
      ]

      expect(entries_for(tables)).to eq(expected)
    end

    it "uses an item number as id when the first cell looks like one" do
      header = [row("", "English", "Francais")]
      rows = [row("12-1.1", "lattice vector", "vecteur du réseau")]
      tables = [table(section: "1.1", header: header, rows: rows)]

      expect(entries_for(tables).first).to include("id" => "12-1.1")
    end

    it "skips letter dividers and rows without equivalences" do
      rows = [row("", "A", "", ""),
              row("", "", "", ""),
              row("1", "fire", "feu", "Feuer")]
      tables = [table(section: "1.1", header: language_header, rows: rows)]

      entries = entries_for(tables)

      expect(entries.size).to eq(1)
      expect(entries.first["id"]).to eq("3")
    end

    it "rejects tables with a single language column" do
      rows = [row("1", "fire")]
      tables = [table(section: "1.1", header: [row("", "English")],
                      rows: rows)]

      expect(entries_for(tables)).to eq([])
    end

    it "yields to the quantity rule when both rules match" do
      rows = [row("12-1.1", "lattice vector", "vecteur du réseau",
                  "Gittervektor")]
      tables = [table(section: "3", header: language_header, rows: rows)]

      expect(entries_for(tables).first).to include(
        "id" => "12-1.1", "designation" => "lattice vector",
      )
    end
  end

  describe "non-term tables" do
    it "rejects a 2-column index table" do
      rows = [row("acceptor density", "12-29.5"), row("activation", "12-4.1")]
      tables = [table(section: "index", header: [row("Name", "Item")],
                      rows: rows, id: "tab_b")]

      expect(entries_for(tables)).to eq([])
    end

    it "rejects a bibliography-like table" do
      rows = [row("[1]", "ISO 80000-1, Quantities and units — Part 1")]
      tables = [table(section: "bibl", header: [], rows: rows)]

      expect(entries_for(tables)).to eq([])
    end
  end

  describe "ISO 80000-12 fixtures" do
    let(:fixture_dir) do
      File.expand_path("../../../../iso-iec-80000/reference-docs", __dir__)
    end

    it "extracts the 60 EN entries with exact first entry" do
      fixture = File.join(fixture_dir, "en/html/ISO-80000-12-E.html")
      skip "Fixture not available" unless File.exist?(fixture)

      entries = entries_from_file(fixture)
      expected_first = {
        "id" => "12-1.1", "designation" => "lattice vector",
        "definition" => "translation vector that maps the crystal lattice " \
                        "on itself",
        "symbol" => "R", "unit" => "m",
        "remarks" => "The non-SI unit ångström (Å) is widely used by x-ray " \
                     "crystallographers and structural chemists.",
        "source" => {
          "table" => "iso_std_iso_80000-12_ed-2_v2_en_tab_1",
          "section" => "3",
        }
      }

      expect(entries.size).to eq(60)
      expect(entries.map { |entry| entry["id"] }.uniq.size).to eq(60)
      expect(entries.first).to eq(expected_first)
    end

    it "extracts the 60 FR entries with exact first entry" do
      fixture = File.join(fixture_dir, "fr/html/ISO-80000-12-F.html")
      skip "Fixture not available" unless File.exist?(fixture)

      entries = entries_from_file(fixture)
      expected_first = {
        "id" => "12-1.1", "designation" => "vecteur du réseau, m",
        "definition" => "vecteur qui reproduit par translation le réseau " \
                        "cristallin sur lui-même",
        "symbol" => "R", "unit" => "m",
        "remarks" => "L’unité non-SI ångström (Å) est largement " \
                     "utilisée par les cristallographes et les chimistes " \
                     "de la structure.",
        "source" => {
          "table" => "iso_std_iso_80000-12_ed-2_v2_fr_tab_1",
          "section" => "3",
        }
      }

      expect(entries.size).to eq(60)
      expect(entries.first).to eq(expected_first)
    end
  end

  describe "ISO 5843-6 equivalent-terms fixture" do
    let(:fixture) do
      File.expand_path("../../../obp-output/5483-6-en.html", __dir__)
    end

    it "extracts multilingual designations from the sts-array" do
      skip "Fixture not available" unless File.exist?(fixture)

      entries = entries_from_file(fixture)
      expected_first = {
        "id" => "2",
        "designations" => { "english" => "absorption, atmospheric",
                            "francais" => "absorption atmosphérique",
                            "deutsch" => "atmosphärische Absorption" },
        "source" => { "section" => "1.1" },
      }

      expect(entries.size).to eq(215)
      expect(entries.first).to eq(expected_first)
    end
  end
end

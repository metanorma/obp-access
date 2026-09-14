# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access do
  describe ".fetch" do
    it "returns an Access instance for a single URN" do
      urn = "iso:std:iso:5598:ed-3:v1:en"
      parser = double(to_xml: "<standard/>", available_languages: %w[fr de])
      allow(Obp::Access::Parser).to receive(:new).and_return(parser)

      access = described_class.fetch(urn)
      expect(access).to be_a(described_class)
      expect(access.urn.to_s).to eq("iso:std:iso:5598:ed-3:v1:en")
    end

    it "raises ArgumentError without URN" do
      expect { described_class.fetch(nil) }.to raise_error(ArgumentError)
    end
  end

  describe ".fetch_all" do
    it "returns separate Access instances per language" do
      urn = "iso:std:iso:5598:ed-3:v1:en"
      parser = double(to_xml: "<standard/>", available_languages: %w[fr de])
      allow(Obp::Access::Parser).to receive(:new).and_return(parser)

      results = described_class.fetch_all(urn, languages: :all)
      expect(results.size).to eq(3)
      expect(results.map { |a| a.urn.language }).to contain_exactly("en", "fr", "de")
    end

    it "filters requested languages against available" do
      urn = "iso:std:iso:5598:ed-3:v1:en"
      parser = double(to_xml: "<standard/>", available_languages: %w[fr de])
      allow(Obp::Access::Parser).to receive(:new).and_return(parser)

      results = described_class.fetch_all(urn, languages: %w[fr])
      expect(results.size).to eq(2)
      expect(results.map { |a| a.urn.language }).to contain_exactly("en", "fr")
    end
  end

  describe ".resolve_languages" do
    it "resolves all 3 ISO official languages (en, fr, ru)" do
      result = described_class.resolve_languages("en", :all, %w[fr ru])
      expect(result).to eq(%w[en fr ru])
    end

    it "resolves Russian as primary with available en/fr" do
      result = described_class.resolve_languages("ru", :all, %w[en fr])
      expect(result).to eq(%w[ru en fr])
    end

    it "deduplicates when primary is also in available" do
      result = described_class.resolve_languages("en", :all, %w[fr ru en])
      expect(result).to eq(%w[en fr ru])
    end
  end

  describe ".from_html" do
    let(:urn) { "iso:std:iso:80000-12:ed-2:v2:en" }
    let(:html) do
      <<~HTML
        <div class="sts-standard">
          <div class="sts-section" id="toc_x_sec_3">
            <div class="sts-table-wrap" id="tab_1">
              <table>
                <thead>
                  <tr><th>Item No.</th><th colspan="3">Quantity</th><th>Unit</th></tr>
                  <tr><th></th><th>Name</th><th>Symbol</th><th>Definition</th>
                    <th></th></tr>
                </thead>
                <tbody><tr><td>12-1.1</td><td>lattice vector</td><td>R</td>
                  <td>definition</td><td>m</td></tr></tbody>
              </table>
            </div>
          </div>
        </div>
      HTML
    end

    it "returns an Access instance" do
      access = described_class.from_html(urn: urn, html: html, caption: "ISO 80000-12:2019")
      expect(access).to be_a(described_class)
      expect(access.urn.to_s).to eq(urn)
    end

    it "raises ArgumentError without URN" do
      expect { described_class.from_html(urn: nil, html: html) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError without HTML" do
      expect { described_class.from_html(urn: urn, html: nil) }.to raise_error(ArgumentError)
    end

    it "converts raw HTML to STS XML without network" do
      access = described_class.from_html(urn: urn, html: html, caption: "ISO 80000-12:2019")
      xml = access.to_xml
      expect(xml).to include("<standard")
      expect(xml).to include("ISO 80000-12:2019")
      expect(xml).to include("lattice vector")
    end

    it "extracts table terms from raw HTML without network" do
      access = described_class.from_html(urn: urn, html: html, caption: "ISO 80000-12:2019")
      terms = YAML.safe_load(access.to_terms)
      expect(terms.size).to eq(1)
      expect(terms.first["designation"]).to eq("lattice vector")
    end

    it "honours supplied titles" do
      access = described_class.from_html(
        urn: urn, html: html, caption: "ISO 80000-12:2019",
        titles: { "en" => "Quantities and units — Part 12: Solid state physics" }
      )
      xml = access.to_xml
      expect(xml).to include("Quantities and units")
    end
  end

  describe "ISO 5843-6 multilingual conversion" do
    let(:fixtures_dir) { File.expand_path("../../../obp-output", __dir__) }
    let(:base_metas) do
      { "titles" => {}, "images" => {}, "description" => "ISO 5843/6",
        "caption" => "ISO 5843/6:1981(en)" }
    end

    it "converts English HTML fixture to valid XML" do
      skip "Fixture not available" unless File.exist?(File.join(fixtures_dir, "5483-6-en.html"))
      urn = Obp::Access::Urn.new("iso:std:iso:5843-6:ed-1:v1:en")
      source = File.read(File.join(fixtures_dir, "5483-6-en.html"))
      metas = base_metas.merge("language" => "en")
      xml = Obp::Access::Converter.new(urn:, metas:, source:).to_xml

      expect(xml).to include("<standard")
      expect(xml).to include("Foreword")
      expect(xml).to include("Scope and field of application")
    end

    it "converts French HTML fixture to valid XML" do
      skip "Fixture not available" unless File.exist?(File.join(fixtures_dir, "5483-6-fr.html"))
      urn = Obp::Access::Urn.new("iso:std:iso:5843-6:ed-1:v1:fr")
      source = File.read(File.join(fixtures_dir, "5483-6-fr.html"))
      metas = base_metas.merge("language" => "fr")
      xml = Obp::Access::Converter.new(urn:, metas:, source:).to_xml

      expect(xml).to include("<standard")
      expect(xml).to include("Avant-propos")
      expect(xml).to include("Objet et domaine d")
    end

    it "converts Russian HTML fixture to valid XML" do
      skip "Fixture not available" unless File.exist?(File.join(fixtures_dir, "5483-6-ru.html"))
      urn = Obp::Access::Urn.new("iso:std:iso:5843-6:ed-1:v1:ru")
      source = File.read(File.join(fixtures_dir, "5483-6-ru.html"))
      metas = base_metas.merge("language" => "ru")
      xml = Obp::Access::Converter.new(urn:, metas:, source:).to_xml

      expect(xml).to include("<standard")
      expect(xml).to include("Введение")
      expect(xml).to include("Объект и область применения")
    end
  end

  describe "#to_sts" do
    it "returns a Sts::NisoSts::Standard" do
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <standard xmlns:xlink="http://www.w3.org/1999/xlink"
                  xmlns:mml="http://www.w3.org/1998/Math/MathML"
                  xmlns:tbx="urn:iso:std:iso:30042:ed-2">
          <front><std-meta><permissions>
            <copyright-statement>All rights reserved</copyright-statement>
            <copyright-holder>ISO</copyright-holder>
          </permissions>
          <title-wrap xml:lang="en"><full>Test Standard</full></title-wrap>
          <proj-id>ISO 5598</proj-id><content-language>en</content-language>
          <std-ref type="dated">ISO 5598:2020</std-ref>
          <std-ref type="undated">ISO 5598</std-ref>
          <doc-ref>ISO 5598:2020</doc-ref>
          </std-meta></front>
          <body><sec id="sec_1"><label>1</label></sec></body>
          <back/>
        </standard>
      XML

      access = described_class.new(Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:en"))
      parser = double(to_xml: xml)
      allow(access).to receive(:parser).and_return(parser)

      result = access.to_sts
      expect(result).to be_a(Sts::NisoSts::Standard)
      expect(result.body.sec.size).to eq(1)
    end
  end

  describe "#to_tables / #to_terms" do
    let(:access) do
      described_class.new(Obp::Access::Urn.new("iso:std:iso:80000-12:ed-2:v2:en"))
    end

    let(:quantity_html) do
      <<~HTML
        <div class="sts-standard">
          <div class="sts-section" id="toc_x_sec_3">
            <div class="sts-table-wrap" id="tab_1">
              <table>
                <thead>
                  <tr><th>Item No.</th><th colspan="3">Quantity</th><th>Unit</th></tr>
                  <tr><th></th><th>Name</th><th>Symbol</th><th>Definition</th>
                    <th></th></tr>
                </thead>
                <tbody><tr><td>12-1.1</td><td>lattice vector</td><td>R</td>
                  <td>definition</td><td>m</td></tr></tbody>
              </table>
            </div>
          </div>
        </div>
      HTML
    end

    def stub_parser(access, html)
      parser = double(html: html)
      allow(access).to receive(:parser).and_return(parser)
    end

    it "serializes the generic table model as YAML" do
      stub_parser(access, quantity_html)

      expected = [
        { "id" => "tab_1", "section" => "3",
          "header" => [
            [{ "text" => "Item No." }, { "text" => "Quantity", "colspan" => 3 },
             { "text" => "Unit" }],
            [{ "text" => "" }, { "text" => "Name" }, { "text" => "Symbol" },
             { "text" => "Definition" }, { "text" => "" }],
          ],
          "rows" => [
            [{ "text" => "12-1.1" }, { "text" => "lattice vector" },
             { "text" => "R" }, { "text" => "definition" }, { "text" => "m" }],
          ] },
      ]

      expect(YAML.safe_load(access.to_tables)).to eq(expected)
    end

    it "serializes extracted term entries as YAML" do
      stub_parser(access, quantity_html)

      expected = [
        { "id" => "12-1.1", "designation" => "lattice vector",
          "definition" => "definition", "symbol" => "R", "unit" => "m",
          "source" => { "table" => "tab_1", "section" => "3" } },
      ]

      expect(YAML.safe_load(access.to_terms)).to eq(expected)
    end

    it "serializes empty arrays when the document has no tables" do
      stub_parser(access, '<div class="sts-standard"></div>')

      expect(access.to_tables).to eq("--- []\n")
      expect(access.to_terms).to eq("--- []\n")
    end
  end
end

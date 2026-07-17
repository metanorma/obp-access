# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::TableWrap do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  def build_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-table-wrap" do
      expect(described_class.classes).to eq(%w[sts-table-wrap])
    end
  end

  describe "#match_node?" do
    it "matches a bare sts-table-wrap div" do
      node = build_node('<div class="sts-table-wrap "><table/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "matches a table wrap with an extra fig-index class" do
      node = build_node('<div class="sts-table-wrap fig-index"><table/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "does not match a table wrap inside a figure (Figure renders the legend)" do
      html = '<div class="sts-fig"><div class="sts-table-wrap fig-index"><table/></div></div>'
      node = Nokogiri::HTML.fragment(html).at_css("div.sts-table-wrap")
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end
  end

  describe "#render" do
    it "renders label, caption title and the table structure" do
      html = <<~HTML
        <div class="sts-table-wrap ">
          <div class="sts-caption">
            <span class="sts-caption-label">Table 1</span> —
            <span class="sts-caption-title">Quantities and units</span>
          </div>
          <table>
            <col width="30%"><col width="70%">
            <thead><tr><th>Item</th></tr></thead>
            <tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody>
          </table>
        </div>
      HTML
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      wrap = document.at_css("body table-wrap")
      expect(wrap.at_css("label").text).to eq("Table 1")
      expect(wrap.at_css("caption title").text).to eq("Quantities and units")
      table = wrap.at_css("table")
      expect(table.children.select(&:element?).map(&:name)).to eq(%w[col col thead tbody])
      expect(table.xpath("tbody/tr").size).to eq(2)
    end

    it "falls back to the caption text when no caption title is present" do
      html = '<div class="sts-table-wrap "><div class="sts-caption">Table without title</div>' \
             "<table><tbody><tr><td>1</td></tr></tbody></table></div>"
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      wrap = document.at_css("body table-wrap")
      expect(wrap.at_css("caption title").text).to eq("Table without title")
      expect(wrap.at_css("label")).to be_nil
    end

    it "strips OBP unknown-element placeholders from the table" do
      html = '<div class="sts-table-wrap "><table><tbody><tr><td><b>' \
             '<span class="sts-unknown-element">[no rendering defined for element: std-ref]</span>' \
             "</b></td></tr></tbody></table></div>"
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      wrap = document.at_css("body table-wrap")
      expect(wrap.text).not_to include("no rendering defined")
    end

    it "renders a wrap without caption" do
      html = '<div class="sts-table-wrap "><table><tbody><tr><td>1</td></tr></tbody></table></div>'
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      wrap = document.at_css("body table-wrap")
      expect(wrap.at_css("label")).to be_nil
      expect(wrap.at_css("caption")).to be_nil
      expect(wrap.at_css("table")).not_to be_nil
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::FigureGroup do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  def build_figure_group_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) do
    { "images" => { "img1.png" => "media/img1.png", "img2.png" => "media/img2.png",
                    "img3.png" => "media/img3.png" } }
  end

  describe ".classes" do
    it "matches sts-fig (same as Figure; distinguished by match_node?)" do
      expect(described_class.classes).to eq(%w[sts-fig])
    end
  end

  describe "#match_node?" do
    it "matches a sts-fig div with more than one img" do
      node = build_figure_group_node('<div class="sts-fig"><img src="a.png"/><img src="b.png"/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "does not match a sts-fig div with only one img (Figure handles that)" do
      node = build_figure_group_node('<div class="sts-fig"><img src="a.png"/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end
  end

  describe "#render" do
    it "renders a fig-group with overall caption and one fig per img" do
      html = <<~HTML
        <div class="sts-fig">
          <div class="sts-caption"><span class="sts-caption-label">Figure 1</span><span class="sts-caption-title">Flow diagrams</span></div><div class="sts-caption"><span class="sts-caption-label">a)</span><span class="sts-caption-title">First diagram</span></div><img src="img1.png"/><div class="sts-caption"><span class="sts-caption-label">b)</span><span class="sts-caption-title">Second diagram</span></div><img src="img2.png"/>
        </div>
      HTML
      node = build_figure_group_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      group = document.at_css("body fig-group")
      expect(group).not_to be_nil
      expect(group.at_css("label").text).to eq("Figure 1")
      expect(group.at_css("caption title").text).to eq("Flow diagrams")

      figs = group.css("fig")
      expect(figs.size).to eq(2)
      expect(figs[0].at_css("label").text).to eq("a)")
      expect(figs[0].at_css("caption title").text).to eq("First diagram")
      expect(figs[1].at_css("label").text).to eq("b)")
    end

    context "when only the first img has a preceding caption div (OBP ISO 19155-2 layout)" do
      it "does not crash and renders fig elements without captions for subsequent imgs" do
        html = <<~HTML
          <div class="sts-fig">
            <div class="sts-caption"><span class="sts-caption-label">Figure 1</span><span class="sts-caption-title">Architecture overview</span></div><div class="sts-caption"><span class="sts-caption-label">a)</span><span class="sts-caption-title">Sub-figure A</span></div><img src="img1.png"/>
            <img src="img2.png"/>
            <img src="img3.png"/>
          </div>
        HTML
        node = build_figure_group_node(html)
        element = described_class.new(document: document, metas: metas, node: node)

        expect { element.render(target: "body") }.not_to raise_error

        figs = document.css("body fig-group fig")
        expect(figs.size).to eq(3)
        expect(figs[0].at_css("label").text).to eq("a)")
        expect(figs[1].at_css("label")).to be_nil
        expect(figs[2].at_css("label")).to be_nil
        expect(figs[1].at_css("graphic")["xlink:href"]).to eq("media/img2.png")
        expect(figs[2].at_css("graphic")["xlink:href"]).to eq("media/img3.png")
      end
    end

    context "when no caption divs exist at all" do
      it "renders fig-group with bare fig elements" do
        html = '<div class="sts-fig"><img src="img1.png"/><img src="img2.png"/></div>'
        node = build_figure_group_node(html)
        element = described_class.new(document: document, metas: metas, node: node)

        expect { element.render(target: "body") }.not_to raise_error

        group = document.at_css("body fig-group")
        expect(group.at_css("label")).to be_nil
        expect(group.css("fig").size).to eq(2)
      end
    end
  end
end

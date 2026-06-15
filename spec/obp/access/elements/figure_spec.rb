# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Figure do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  def build_figure_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { { "images" => { "fig1.png" => "media/fig1.png" } } }

  describe ".classes" do
    it "matches sts-fig" do
      expect(described_class.classes).to eq(%w[sts-fig])
    end
  end

  describe "#match_node?" do
    it "matches a sts-fig div with exactly one image" do
      node = build_figure_node('<div class="sts-fig"><img src="fig1.png"/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "does not match a sts-fig div without an image" do
      node = build_figure_node('<div class="sts-fig"><p>text</p></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end

    it "does not match a sts-fig div with multiple images (FigureGroup handles that)" do
      node = build_figure_node('<div class="sts-fig"><img src="a.png"/><img src="b.png"/></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end
  end

  describe "#render" do
    it "renders a figure with caption and graphic" do
      html = <<~HTML
        <div class="sts-fig" id="fig_1">
          <div class="sts-caption">
            <span class="sts-caption-label">Figure 1</span>
            <span class="sts-caption-title">Hydraulic circuit</span>
          </div>
          <img src="fig1.png"/>
        </div>
      HTML
      node = build_figure_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      fig = document.at_css("body fig")
      expect(fig).not_to be_nil
      expect(fig.at_css("label").text).to eq("Figure 1")
      expect(fig.at_css("caption title").text).to eq("Hydraulic circuit")
      graphic = fig.at_css("graphic")
      expect(graphic["xlink:href"]).to eq("media/fig1.png")
    end

    it "renders a figure with a legend table" do
      html = <<~HTML
        <div class="sts-fig" id="fig_2">
          <img src="fig1.png"/>
          <div class="sts-table-wrap fig-index">
            <div class="sts-caption">
              <span class="sts-caption-title">Key</span>
            </div>
            <table><tr><td>1</td><td>pump</td></tr></table>
          </div>
        </div>
      HTML
      node = build_figure_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      fig = document.at_css("body fig")
      legend = fig.at_css("table-wrap")
      expect(legend).not_to be_nil
      expect(legend["content-type"]).to eq("legend")
      expect(legend.at_css("caption title").text).to eq("Key")
    end

    it "renders a figure without caption" do
      html = '<div class="sts-fig" id="fig_3"><img src="fig1.png"/></div>'
      node = build_figure_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      fig = document.at_css("body fig")
      expect(fig).not_to be_nil
      expect(fig.at_css("caption")).to be_nil
      expect(fig.at_css("graphic")).not_to be_nil
    end
  end
end

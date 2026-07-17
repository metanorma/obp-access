# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::DispFormula do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  def build_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { { "images" => {} } }

  describe ".classes" do
    it "matches sts-disp-formula-panel" do
      expect(described_class.classes).to eq(%w[sts-disp-formula-panel])
    end
  end

  describe "#render" do
    it "renders an image formula as a graphic with the original src" do
      html = '<div class="sts-disp-formula-panel"><a id="a_x"></a>' \
             '<img class="math" src="/obp/graphics/mml_m1"/>' \
             '<div class="sts-disp-formula-label"></div></div>'
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      formula = document.at_css("body disp-formula")
      expect(formula.at_css("graphic")["xlink:href"]).to eq("/obp/graphics/mml_m1")
      expect(formula.at_css("label")).to be_nil
    end

    it "uses the downloaded image path when available" do
      html = '<div class="sts-disp-formula-panel"><img class="math" src="/obp/graphics/mml_m1"/></div>'
      node = build_node(html)
      metas = { "images" => { "/obp/graphics/mml_m1" => "media/mml_m1.png" } }
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      graphic = document.at_css("body disp-formula graphic")
      expect(graphic["xlink:href"]).to eq("media/mml_m1.png")
    end

    it "preserves the MathML subtree" do
      html = '<div class="sts-disp-formula-panel"><math><mi>x</mi></math></div>'
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      formula = document.at_css("body disp-formula")
      expect(formula.to_xml).to include("<mi>x</mi>")
      expect(formula.at_css("graphic")).to be_nil
    end

    it "renders the label when present" do
      html = '<div class="sts-disp-formula-panel"><img class="math" src="/obp/graphics/mml_m2"/>' \
             '<div class="sts-disp-formula-label">(1)</div></div>'
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      formula = document.at_css("body disp-formula")
      expect(formula.at_css("label").text).to eq("(1)")
    end
  end
end

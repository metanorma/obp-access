# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Index do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  def build_index_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-section" do
      expect(described_class.classes).to eq(%w[sts-section])
    end
  end

  describe "#match_node?" do
    it "matches a section with sec_index id" do
      node = build_index_node('<div class="sts-section" id="sec_index"></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "matches a section with Index title" do
      node = build_index_node('<div class="sts-section" id="sec_other"><h1 class="sts-sec-title">Index</h1></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "matches a section with Sachverzeichnis title" do
      html = '<div class="sts-section" id="sec_other">' \
             '<h1 class="sts-sec-title">Sachverzeichnis</h1></div>'
      node = build_index_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end

    it "does not match a regular section" do
      node = build_index_node('<div class="sts-section" id="sec_3"><h1 class="sts-sec-title">Terms</h1></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end

    it "does not match nodes without sts-section class" do
      node = build_index_node('<div class="sts-p" id="sec_index"></div>')
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be false
    end
  end

  describe "#render" do
    it "renders index entries grouped by letter" do
      html = <<~HTML
        <div class="sts-section" id="sec_index">
          <h1 class="sts-sec-title">Index</h1>
          <div class="sts-p"><b>A</b></div>
          <div class="sts-p">accumulator <a class="sts-xref" href="#iso:std:iso:5598:ed-3:v1:en:term:3.1.1">3.1.1</a></div>
          <div class="sts-p"><b>B</b></div>
          <div class="sts-p">block <a class="sts-xref" href="#iso:std:iso:5598:ed-3:v1:en:term:3.2.1">3.2.1</a></div>
        </div>
      HTML
      node = build_index_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      body = document.at_css("body")
      sec = body.at_css("sec")
      expect(sec).not_to be_nil
      expect(sec["id"]).to eq("sec_index")
      expect(sec.at_css("title").text).to eq("Index")

      divs = sec.css("index-div")
      expect(divs.length).to eq(2)
      expect(divs[0].at_css("title").text).to eq("A")
      expect(divs[0].at_css("index-entry term").text).to eq("accumulator")
      expect(divs[1].at_css("title").text).to eq("B")
    end

    it "renders xrefs with sec ref-type" do
      html = <<~HTML
        <div class="sts-section" id="sec_index">
          <h1 class="sts-sec-title">Index</h1>
          <div class="sts-p"><b>A</b></div>
          <div class="sts-p">actuator <a class="sts-xref" href="#iso:std:iso:5598:ed-3:v1:en:term:3.1.2">3.1.2</a></div>
        </div>
      HTML
      node = build_index_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      xref = document.at_css("xref")
      expect(xref["ref-type"]).to eq("sec")
      expect(xref["rid"]).to eq("sec_3.1.2")
    end
  end
end

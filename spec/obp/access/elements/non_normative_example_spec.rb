# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::NonNormativeExample do
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
    it "matches sts-non-normative-example" do
      expect(described_class.classes).to eq(%w[sts-non-normative-example])
    end
  end

  describe "#render" do
    it "renders the example with its label" do
      html = <<~HTML
        <div class="sts-non-normative-example">
          <p><span class="sts-non-normative-example-label">EXAMPLE 1</span></p>
          <div class="sts-p">for chemical potential of pure substance B.</div>
        </div>
      HTML
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      example = document.at_css("body non-normative-example")
      expect(example.at_css("label").text).to eq("EXAMPLE 1")
    end

    it "renders without a label when none is present" do
      html = '<div class="sts-non-normative-example"><div class="sts-p">text</div></div>'
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: "body")

      example = document.at_css("body non-normative-example")
      expect(example).not_to be_nil
      expect(example.at_css("label")).to be_nil
    end
  end
end

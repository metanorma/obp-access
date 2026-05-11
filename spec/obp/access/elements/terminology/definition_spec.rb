# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Terminology::Definition do
  def build_document
    Nokogiri::XML(<<~XML)
      <standard xmlns:xlink="http://www.w3.org/1999/xlink">
        <body>
          <tbx:termEntry id="term_3.1.1">
            <tbx:langSet xml:lang="en"/>
          </tbx:termEntry>
        </body>
      </standard>
    XML
  end

  def build_node(html)
    doc = Nokogiri::HTML.fragment("<div class=\"sts-tbx-def\">#{html}</div>")
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-tbx-def" do
      expect(described_class.classes).to eq(%w[sts-tbx-def])
    end
  end

  describe "#match_node?" do
    it "matches a sts-tbx-def div" do
      node = build_node("a device that moves fluid")
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end
  end
end

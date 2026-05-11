# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Terminology::Tig do
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

  def build_node(inner_html)
    doc = Nokogiri::HTML.fragment(<<~HTML)
      <div class="sts-tbx-sec">
        <div class="sts-tbx-label">3.1.1</div>
        <div class="sts-tbx-term">#{inner_html}</div>
      </div>
    HTML
    doc.at_css("div.sts-tbx-term")
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-tbx-term" do
      expect(described_class.classes).to eq(%w[sts-tbx-term])
    end
  end

  describe "#match_node?" do
    it "matches a sts-tbx-term div" do
      node = build_node("pump")
      element = described_class.new(document: document, metas: metas, node: node)
      expect(element.match_node?).to be true
    end
  end
end

RSpec.describe Obp::Access::Renderer::Elements::Terminology::TigPreferred do
  describe ".classes" do
    it "matches sts-tbx-term preferredTerm" do
      expect(described_class.classes).to eq(%w[sts-tbx-term preferredTerm])
    end
  end
end

RSpec.describe Obp::Access::Renderer::Elements::Terminology::TigAdmitted do
  describe ".classes" do
    it "matches sts-tbx-term admittedTerm" do
      expect(described_class.classes).to eq(%w[sts-tbx-term admittedTerm])
    end
  end
end

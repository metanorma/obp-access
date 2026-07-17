# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::ProtectedContentNote do
  def build_document
    Nokogiri::XML('<standard xmlns:xlink="http://www.w3.org/1999/xlink"><body/></standard>')
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-protected-content-note" do
      expect(described_class.classes).to eq(%w[sts-protected-content-note])
    end
  end

  describe "#render" do
    it "renders nothing and returns nil to halt recursion" do
      html = '<div class="sts-protected-content-note">' \
             '<div class="sts-protected-content-note-text">' \
             "Only informative sections of standards are publicly available.</div></div>"
      node = Nokogiri::HTML.fragment(html).at_css("div")
      element = described_class.new(document: document, metas: metas, node: node)

      expect(element.render(target: "body")).to be_nil
      expect(document.at_css("body").element_children).to be_empty
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Footnotes do
  def build_document
    Nokogiri::XML("<standard><body/><back/></standard>")
  end

  def build_node(html)
    doc = Nokogiri::HTML.fragment(html)
    doc.at_css("div")
  end

  let(:document) { build_document }
  let(:metas) { {} }

  describe ".classes" do
    it "matches sts-footnotes" do
      expect(described_class.classes).to eq(%w[sts-footnotes])
    end
  end

  describe "#render" do
    it "renders an fn-group in the back matter" do
      html = <<~HTML
        <div class="sts-footnotes">
          <hr>
          <div class="sts-fn" id="iso_std_iso_x_en_fn_1">
            <a id="a_iso_std_iso_x_en_fn_1"></a>
            <div>1 Under preparation. Stage at the time of publication: ISO/FDIS 17573-2.</div>
          </div>
          <div class="sts-fn" id="iso_std_iso_x_en_fn_2">
            <a id="a_iso_std_iso_x_en_fn_2"></a>
            <div>2 Replaced by ISO/DIS 17573-2.</div>
          </div>
        </div>
      HTML
      node = build_node(html)
      element = described_class.new(document: document, metas: metas, node: node)
      element.render(target: nil)

      group = document.at_css("back fn-group")
      fns = group.css("fn")
      expect(fns.size).to eq(2)
      expect(fns[0]["id"]).to eq("fn_1")
      expect(fns[0].at_css("label").text).to eq("1")
      expect(fns[0].at_css("p").text).to eq("Under preparation. Stage at the time of publication: ISO/FDIS 17573-2.")
      expect(fns[1]["id"]).to eq("fn_2")
      expect(fns[1].at_css("p").text).to eq("Replaced by ISO/DIS 17573-2.")
    end
  end
end

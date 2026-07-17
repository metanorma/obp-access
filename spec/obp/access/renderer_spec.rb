# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer do
  let(:urn) { Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:en") }
  let(:metas) do
    { "titles" => { "en" => "Vocabulary" }, "images" => {},
      "language" => "en", "description" => "x",
      "caption" => "ISO 5598:2020(en)" }
  end

  def render_html(html)
    source = %(<div class="sts-standard">#{html}</div>).gsub(/[[:space:]]/, " ")
    nodes = Nokogiri::HTML(source).css("body > div.sts-standard").children
    described_class.new(urn: urn, metas: metas, nodes: nodes).to_xml
  end

  describe "class matching" do
    it "tolerates a different class order on the node" do
      html = '<div class="sts-ref-list sts-section" id="toc_x_sec_bibl">' \
             "<table><tr><th>Reference</th></tr></table></div>"
      xml = render_html(html)
      expect(xml).to include("<ref-list")
    end

    it "tolerates extra classes on the node" do
      xml = render_html('<div class="sts-p commentable">floating text</div>')
      expect(xml).to include("<p>floating text</p>")
    end

    it "renders the most specific matching element only, exactly once" do
      html = '<div class="sts-section sts-tbx-sec" id="toc_x_sec_3.1">' \
             '<h1 class="sts-sec-title">3.1  term</h1>' \
             '<span class="sts-tbx-def">definition</span></div>'
      xml = render_html(html)
      expect(xml.scan("<term-sec").size).to eq(1)
      expect(xml.scan("<tbx:termEntry").size).to eq(1)
      expect(xml.scan("<tbx:definition>").size).to eq(1)
      expect(xml).not_to include('<sec id="sec_3.1"')
    end
  end

  describe "skip elements" do
    it "halts recursion into the skipped subtree" do
      html = '<div class="sts-protected-content-note">' \
             '<div class="sts-p">paywalled content</div></div>'
      xml = render_html(html)
      expect(xml).not_to include("paywalled content")
    end
  end

  describe "content coverage" do
    it "renders a table wrap inside a section as table-wrap" do
      html = '<div class="sts-section" id="toc_x_sec_5">' \
             '<h1 class="sts-sec-title">5  Quantities</h1>' \
             '<div class="sts-table-wrap ">' \
             '<div class="sts-caption">' \
             '<span class="sts-caption-label">Table 1</span> — ' \
             '<span class="sts-caption-title">Quantities and units</span>' \
             "</div>" \
             "<table><thead><tr><th>Item</th></tr></thead>" \
             "<tbody><tr><td>1</td></tr><tr><td>2</td></tr></tbody></table>" \
             "</div></div>"
      xml = render_html(html)
      expect(xml).to include("<table-wrap>")
      expect(xml).to include("<label>Table 1</label>")
      expect(xml).to include("<title>Quantities and units</title>")
      expect(xml.scan("<tr>").size).to eq(3)
    end

    it "never leaks the paywall placeholder text" do
      html = '<div class="sts-section" id="toc_x_sec_1">' \
             '<h1 class="sts-sec-title">1  Scope</h1></div>' \
             '<div class="sts-protected-content-note">' \
             '<div class="sts-protected-content-note-text">' \
             "Only informative sections of standards are publicly available." \
             "</div></div>"
      xml = render_html(html)
      expect(xml).not_to include("Only informative sections")
    end
  end
end

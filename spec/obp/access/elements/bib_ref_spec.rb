# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::BibRef do
  def build_row(ref_html, anchor_name = nil)
    anchor_html = anchor_name ? %(<a name="#{anchor_name}" id="#{anchor_name.tr(':', '_')}"></a>) : ""
    Nokogiri::HTML(<<~HTML).at_css("tr")
      <tr>
        <td class="sts-label">#{anchor_html}</td>
        <td>#{ref_html}</td>
      </tr>
    HTML
  end

  describe "#index" do
    it "extracts ref number" do
      row = build_row("[1]\tISO 554, <i>Specifications</i>")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.index).to eq(1)
    end

    it "extracts multi-digit ref number" do
      row = build_row("[12]\tISO 3857, <i>Vocabulary</i>")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.index).to eq(12)
    end
  end

  describe "#std_ref_text" do
    it "extracts std ref before comma" do
      row = build_row("[1]  ISO 554, <i>Specifications</i>")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.std_ref_text).to eq("ISO 554")
    end

    it "handles ref without title" do
      row = build_row("[5]  ISO 1998-1")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.std_ref_text).to eq("ISO 1998-1")
      expect(ref.title_text).to be_nil
    end
  end

  describe "#title_text" do
    it "extracts title from italic" do
      row = build_row("[1]  ISO 554, <i>Standard atmospheres</i>")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.title_text).to eq("Standard atmospheres")
    end
  end

  describe "#type" do
    it "returns 'dated' when std-ref has year" do
      row = build_row("[1]  ISO 5598:2008, <i>Vocabulary</i>", "iso:std:iso:5598:ed-2:v1:en:ref:1")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.type).to eq("dated")
    end

    it "returns 'undated' when no year" do
      row = build_row("[1]  ISO 554, <i>Specifications</i>", "iso:std:iso:554:ed-1:v1:en:ref:1")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.type).to eq("undated")
    end
  end

  describe "#std_id" do
    it "extracts std-id from anchor name" do
      row = build_row("[1]  ISO 554, <i>Specifications</i>", "iso:std:iso:554:ed-1:v1:en:ref:1")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.std_id).to eq("iso:std:iso:554:ed-1:v1:en")
    end

    it "returns nil when anchor has no :ref:" do
      row = build_row("[1]  ISO 554, <i>Specs</i>", "some-other-id")
      anchor = row.at_css("a[name]")
      ref = described_class.new(row.css("td:last-child"), anchor)
      expect(ref.std_id).to be_nil
    end

    it "returns nil when no anchor" do
      row = build_row("[1]  ISO 554, <i>Specs</i>")
      ref = described_class.new(row.css("td:last-child"), nil)
      expect(ref.std_id).to be_nil
    end
  end
end

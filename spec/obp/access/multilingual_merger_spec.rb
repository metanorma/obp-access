# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::MultilingualMerger do
  def build_primary_document
    Nokogiri::XML(<<~XML)
      <standard xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:tbx="urn:iso:std:iso:30042:ed-2">
        <body>
          <tbx:termEntry id="term_3.1.1">
            <tbx:langSet xml:lang="en">
              <tbx:tig>
                <tbx:term>pump</tbx:term>
                <tbx:partOfSpeech value="noun"/>
              </tbx:tig>
            </tbx:langSet>
          </tbx:termEntry>
        </body>
      </standard>
    XML
  end

  def build_fr_html
    <<~HTML
      <html><body>
        <div class="sts-standard">
          <div class="sts-section sts-tbx-sec">
            <div class="sts-tbx-label">3.1.1</div>
            <div class="sts-tbx-term"><b>f</b> pompe</div>
            <div class="sts-tbx-def">dispositif de transfert de fluide</div>
          </div>
        </div>
      </body></html>
    HTML
  end

  def build_de_html
    <<~HTML
      <html><body>
        <div class="sts-standard">
          <div class="sts-section sts-tbx-sec">
            <div class="sts-tbx-label">3.1.1</div>
            <div class="sts-tbx-term"><b>f</b> Pumpe</div>
            <div class="sts-tbx-def">Fluidfördermaschine</div>
          </div>
        </div>
      </body></html>
    HTML
  end

  describe "#merge" do
    it "merges additional language langSets into primary document" do
      doc = build_primary_document
      merger = described_class.new(doc, { "fr" => build_fr_html }, {})
      result = merger.merge

      entry = result.at_xpath("//*[local-name()='termEntry' and @id='term_3.1.1']")
      lang_sets = entry.xpath("./*[local-name()='langSet']")
      expect(lang_sets.length).to eq(2)

      fr_lang = lang_sets.last
      expect(fr_lang["xml:lang"]).to eq("fr")

      tigs = fr_lang.xpath("./*[local-name()='tig']")
      expect(tigs.length).to eq(1)
      term = tigs.first.xpath("./*[local-name()='term']").first
      expect(term.text).to eq("pompe")

      gram = tigs.first.xpath("./*[local-name()='gram']").first
      expect(gram["value"]).to eq("f")
      expect(gram["type"]).to eq("gender")
    end

    it "merges multiple languages" do
      doc = build_primary_document
      merger = described_class.new(doc, { "fr" => build_fr_html, "de" => build_de_html }, {})
      result = merger.merge

      entry = result.at_xpath("//*[local-name()='termEntry' and @id='term_3.1.1']")
      lang_sets = entry.xpath("./*[local-name()='langSet']")
      expect(lang_sets.length).to eq(3)
    end

    it "returns the modified document" do
      doc = build_primary_document
      merger = described_class.new(doc, {}, {})
      expect(merger.merge).to equal(doc)
    end

    it "skips languages with no standard div" do
      doc = build_primary_document
      merger = described_class.new(doc, { "fr" => "<html><body></body></html>" }, {})
      result = merger.merge

      entry = result.at_xpath("//*[local-name()='termEntry' and @id='term_3.1.1']")
      lang_sets = entry.xpath("./*[local-name()='langSet']")
      expect(lang_sets.length).to eq(1)
    end

    it "skips terms not found in primary document" do
      html = <<~HTML
        <html><body>
          <div class="sts-standard">
            <div class="sts-section sts-tbx-sec">
              <div class="sts-tbx-label">9.9.9</div>
              <div class="sts-tbx-term">inconnu</div>
            </div>
          </div>
        </body></html>
      HTML
      doc = build_primary_document
      merger = described_class.new(doc, { "fr" => html }, {})
      result = merger.merge

      entry = result.at_xpath("//*[local-name()='termEntry' and @id='term_3.1.1']")
      lang_sets = entry.xpath("./*[local-name()='langSet']")
      expect(lang_sets.length).to eq(1)
    end
  end
end

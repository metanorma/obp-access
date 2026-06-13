# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Terminology::Tig do
  def build_document
    Nokogiri::XML(<<~XML)
      <standard xmlns:tbx="urn:iso:std:iso:30042:ed-2"
                xmlns:xlink="http://www.w3.org/1999/xlink">
        <body>
          <tbx:termEntry id="term_3.1.1">
            <tbx:langSet xml:lang="en"/>
          </tbx:termEntry>
        </body>
      </standard>
    XML
  end

  def build_node(inner_html)
    doc = Nokogiri::HTML::Document.parse(<<~HTML)
      <html><body>
        <div class="sts-tbx-sec">
          <div class="sts-tbx-label">3.1.1</div>
          <div class="sts-tbx-term">#{inner_html}</div>
        </div>
      </body></html>
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

  describe "grammaticalGender rendering" do
    let(:gender_test_class) do
      Class.new(described_class) do
        def build_gender_xml
          result = Obp::Access::GrammarParser.parse(node.inner_html)
          Nokogiri::XML::Builder.new do |xml|
            xml.root do
              render_genders(xml, result.genders)
            end
          end.doc.root.to_xml
        end
      end
    end

    def rendered_genders(inner_html)
      node = build_node(inner_html)
      element = gender_test_class.new(document: document, metas: metas, node: node)
      element.build_gender_xml
    end

    it "emits tbx:grammaticalGender for a feminine term" do
      expect(rendered_genders("<b>f</b> pompe")).to include('value="feminine"')
    end

    it "emits tbx:grammaticalGender for a masculine term" do
      expect(rendered_genders("<b>m</b> Kolben")).to include('value="masculine"')
    end

    it "emits tbx:grammaticalGender for a neuter term" do
      expect(rendered_genders("<b>n</b> Ventil")).to include('value="neuter"')
    end

    it "emits multiple tbx:grammaticalGender elements for multi-gender terms" do
      xml = rendered_genders("<b>m, n</b> Gehäuse")
      expect(xml.scan("grammaticalGender").length).to eq(2)
    end

    it "does not emit the legacy tbx:gram element" do
      xml = rendered_genders("<b>f</b> pompe")
      expect(xml).not_to match(/tbx:gram\b(?!aticalGender)/)
    end

    it "omits grammaticalGender when no gender marker is present" do
      expect(rendered_genders("pump")).not_to include("grammaticalGender")
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

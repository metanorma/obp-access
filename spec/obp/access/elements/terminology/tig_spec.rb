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

  def tig_target_path
    "/standard/body"
  end

  def render_tig(inner_html)
    document = build_document
    element = described_class.new(document: document, metas: { "language" => "en" }, node: build_node(inner_html))
    element.render(target: tig_target_path)
    document.remove_namespaces!
    document.at_css("tig")
  end

  describe ".classes" do
    it "matches sts-tbx-term only (fallback for unmarked terms)" do
      expect(described_class.classes).to eq(%w[sts-tbx-term])
    end
  end

  describe "#match_node?" do
    it "matches a sts-tbx-term div" do
      document = build_document
      element = described_class.new(document: document, metas: { "language" => "en" }, node: build_node("pump"))
      expect(element.match_node?).to be true
    end
  end

  describe "NORMATIVE_AUTHORIZATION" do
    it "defaults to preferredTerm per the TBX spec" do
      expect(described_class::NORMATIVE_AUTHORIZATION).to eq("preferredTerm")
    end
  end

  describe "#render" do
    it "wraps term, partOfSpeech, grammaticalGender, and normativeAuthorization in <tbx:tig>" do
      tig = render_tig("<b>m</b> Kolben")
      expect(tig["id"]).to start_with("term_3.1.1-")
      expect(tig.at_css("term").content).to eq("Kolben")
      expect(tig.at_css("partOfSpeech")["value"]).to eq("noun")
      expect(tig.at_css("normativeAuthorization")["value"]).to eq("preferredTerm")
    end

    it "emits grammaticalGender value=feminine for a feminine term" do
      tig = render_tig("<b>f</b> pompe")
      expect(tig.at_css("grammaticalGender")["value"]).to eq("feminine")
    end

    it "emits grammaticalGender value=masculine for a masculine term" do
      tig = render_tig("<b>m</b> Kolben")
      expect(tig.at_css("grammaticalGender")["value"]).to eq("masculine")
    end

    it "emits grammaticalGender value=neuter for a neuter term" do
      tig = render_tig("<b>n</b> Ventil")
      expect(tig.at_css("grammaticalGender")["value"]).to eq("neuter")
    end

    it "emits one grammaticalGender per gender for multi-gender terms" do
      tig = render_tig("<b>m, n</b> Gehäuse")
      genders = tig.css("grammaticalGender").map { |n| n["value"] }
      expect(genders).to eq(%w[masculine neuter])
    end

    it "does not emit the legacy <tbx:gram> element" do
      tig = render_tig("<b>f</b> pompe")
      expect(tig.css("gram")).to be_empty
    end

    it "omits grammaticalGender when no gender marker is present" do
      tig = render_tig("pump")
      expect(tig.css("grammaticalGender")).to be_empty
    end
  end
end

RSpec.describe Obp::Access::Renderer::Elements::Terminology::TigPreferred do
  it "declares preferredTerm normative authorization" do
    expect(described_class::NORMATIVE_AUTHORIZATION).to eq("preferredTerm")
  end

  it "matches sts-tbx-term preferredTerm" do
    expect(described_class.classes).to eq(%w[sts-tbx-term preferredTerm])
  end
end

RSpec.describe Obp::Access::Renderer::Elements::Terminology::TigAdmitted do
  it "declares admittedTerm normative authorization" do
    expect(described_class::NORMATIVE_AUTHORIZATION).to eq("admittedTerm")
  end

  it "matches sts-tbx-term admittedTerm" do
    expect(described_class.classes).to eq(%w[sts-tbx-term admittedTerm])
  end
end

RSpec.describe Obp::Access::Renderer::Elements::Terminology::TigDeprecated do
  def build_document
    Nokogiri::XML(<<~XML)
      <standard xmlns:tbx="urn:iso:std:iso:30042:ed-2">
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
          <div class="sts-tbx-term deprecatedTerm">#{inner_html}</div>
        </div>
      </body></html>
    HTML
    doc.at_css("div.sts-tbx-term")
  end

  it "declares deprecatedTerm normative authorization" do
    expect(described_class::NORMATIVE_AUTHORIZATION).to eq("deprecatedTerm")
  end

  it "matches sts-tbx-term deprecatedTerm" do
    expect(described_class.classes).to eq(%w[sts-tbx-term deprecatedTerm])
  end

  it "strips the deprecation label and renders the deprecated term" do
    document = build_document
    node = build_node('<span class="sts-tbx-term-depr-label">deprecated:</span> Kolben')
    element = described_class.new(document: document, metas: { "language" => "en" }, node: node)
    element.render(target: "/standard/body")
    document.remove_namespaces!
    tig = document.at_css("tig")
    expect(tig.at_css("term").content).to eq("Kolben")
    expect(tig.at_css("normativeAuthorization")["value"]).to eq("deprecatedTerm")
  end
end

RSpec.describe "Tig element registration" do
  it "registers Tig (fallback) and its three subclasses" do
    registered = Obp::Access::ElementRegistry.elements
    expect(registered).to include(Obp::Access::Renderer::Elements::Terminology::Tig)
    expect(registered).to include(Obp::Access::Renderer::Elements::Terminology::TigPreferred)
    expect(registered).to include(Obp::Access::Renderer::Elements::Terminology::TigAdmitted)
    expect(registered).to include(Obp::Access::Renderer::Elements::Terminology::TigDeprecated)
  end
end

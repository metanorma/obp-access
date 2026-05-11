# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::DomainExtractor do
  def build_node(inner_html)
    wrapped = "<div class=\"sts-tbx-def\">#{inner_html}</div>"
    doc = Nokogiri::HTML.fragment(wrapped)
    doc.at_css("div")
  end

  describe ".extract" do
    it "returns empty domains when no domain markers" do
      node = build_node("simple definition text")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
    end

    it "extracts a single domain" do
      node = build_node("&lt;hydraulic&gt; a fluid power system")
      result = described_class.extract(node)
      expect(result.domains).to eq(["hydraulic"])
    end

    it "extracts multiple domains" do
      node = build_node("&lt;hydraulic&gt; &lt;pneumatic&gt; a system")
      result = described_class.extract(node)
      expect(result.domains).to eq(%w[hydraulic pneumatic])
    end

    it "returns remaining children as clean_children" do
      node = build_node("&lt;hydraulic&gt; a fluid power system")
      result = described_class.extract(node)
      expect(result.clean_children).not_to be_empty
      text = result.clean_children.first
      expect(text.content.strip).to eq("a fluid power system")
    end

    it "skips non-text leading children" do
      node = build_node("<b>bold definition</b>")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
      expect(result.clean_children.first.name).to eq("b")
    end

    it "rejects domains with parentheses" do
      node = build_node("&lt;domain (invalid)&gt; text")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
    end

    it "rejects domains with multi-digit numbers" do
      node = build_node("&lt;ISO 5598&gt; text")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
    end

    it "rejects domains longer than 50 characters" do
      long = "a" * 51
      node = build_node("&lt;#{long}&gt; text")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
    end

    it "returns a Result struct" do
      node = build_node("text")
      result = described_class.extract(node)
      expect(result).to be_a(Struct)
      expect(result.members).to eq(%i[domains clean_children])
    end

    it "stops domain extraction after first non-domain text" do
      node = build_node("not a domain &lt;hydraulic&gt; text")
      result = described_class.extract(node)
      expect(result.domains).to eq([])
    end

    it "handles domain followed by element child" do
      node = build_node("&lt;hydraulic&gt; <b>bold part</b>")
      result = described_class.extract(node)
      expect(result.domains).to eq(["hydraulic"])
      expect(result.clean_children.map(&:name)).to include("b")
    end
  end
end

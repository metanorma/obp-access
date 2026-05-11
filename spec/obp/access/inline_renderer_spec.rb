# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::InlineRenderer do
  let(:dummy_class) do
    Class.new do
      include Obp::Access::InlineRenderer

      def build_xml(&)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.root(&)
        end
        builder.doc.root
      end
    end
  end

  let(:renderer) { dummy_class.new }

  describe "#inline_type" do
    it "returns :text for text nodes" do
      node = Nokogiri::HTML.fragment("hello").children.first
      expect(renderer.inline_type(node)).to eq(:text)
    end

    it "returns :entailed_term for sts-tbx-entailedTerm" do
      html = '<span class="sts-tbx-entailedTerm">' \
             '<a href="#iso:std:iso:5598:ed-3:v1:en:term:3.2.2">term</a></span>'
      node = Nokogiri::HTML.fragment(html).children.first
      expect(renderer.inline_type(node)).to eq(:entailed_term)
    end

    it "returns :xref for sts-xref" do
      html = '<a class="sts-xref" ' \
             'href="#iso:std:iso:5598:ed-3:v1:en:sec:3.2">Clause 3.2</a>'
      node = Nokogiri::HTML.fragment(html).children.first
      expect(renderer.inline_type(node)).to eq(:xref)
    end

    it "returns :std_ref for sts-std-ref" do
      node = Nokogiri::HTML.fragment('<span class="sts-std-ref">ISO 5598</span>').children.first
      expect(renderer.inline_type(node)).to eq(:std_ref)
    end

    it "returns :italic for <i> tags" do
      node = Nokogiri::HTML.fragment("<i>italic text</i>").children.first
      expect(renderer.inline_type(node)).to eq(:italic)
    end

    it "returns :bold for <b> tags" do
      node = Nokogiri::HTML.fragment("<b>bold text</b>").children.first
      expect(renderer.inline_type(node)).to eq(:bold)
    end

    it "returns :ext_link for <a> tags" do
      node = Nokogiri::HTML.fragment('<a href="http://example.com">link</a>').children.first
      expect(renderer.inline_type(node)).to eq(:ext_link)
    end

    it "returns :label for sts-label" do
      node = Nokogiri::HTML.fragment('<span class="sts-label">1)</span>').children.first
      expect(renderer.inline_type(node)).to eq(:label)
    end

    it "returns :element for unknown elements" do
      node = Nokogiri::HTML.fragment("<span>generic</span>").children.first
      expect(renderer.inline_type(node)).to eq(:element)
    end
  end

  describe "#xref_ref_type" do
    it "returns 'fig' for Figure references" do
      expect(renderer.xref_ref_type("Figure 1")).to eq("fig")
    end

    it "returns 'table' for Table references" do
      expect(renderer.xref_ref_type("Table 2")).to eq("table")
    end

    it "returns 'sec' for Clause references" do
      expect(renderer.xref_ref_type("Clause 3")).to eq("sec")
    end

    it "returns 'fn' for Note references" do
      expect(renderer.xref_ref_type("Note 1")).to eq("fn")
    end

    it "defaults to 'sec'" do
      expect(renderer.xref_ref_type("something else")).to eq("sec")
    end
  end

  describe "#render_inline" do
    it "renders plain text" do
      node = Nokogiri::HTML.fragment("hello world").children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      expect(result.text).to eq("hello world")
    end

    it "renders italic" do
      node = Nokogiri::HTML.fragment("<i>emphasis</i>").children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      expect(result.at_css("italic").text).to eq("emphasis")
    end

    it "renders bold" do
      node = Nokogiri::HTML.fragment("<b>strong</b>").children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      expect(result.at_css("bold").text).to eq("strong")
    end

    it "skips label nodes" do
      node = Nokogiri::HTML.fragment('<span class="sts-label">1)</span>').children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      expect(result.children.length).to eq(0)
    end

    it "renders nested inline elements" do
      node = Nokogiri::HTML.fragment("<b>bold <i>and italic</i></b>").children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      expect(result.at_css("bold").text).to eq("bold and italic")
      expect(result.at_css("bold italic").text).to eq("and italic")
    end

    it "renders xref with correct ref-type" do
      html = '<a class="sts-xref" href="#iso:std:iso:5598:ed-3:v1:en:sec:3.2">Clause 3.2</a>'
      node = Nokogiri::HTML.fragment(html).children.first
      result = renderer.build_xml { |xml| renderer.render_inline(xml, node) }
      xref = result.at_css("xref")
      expect(xref["ref-type"]).to eq("sec")
      expect(xref["rid"]).to eq("sec_3.2")
    end
  end
end

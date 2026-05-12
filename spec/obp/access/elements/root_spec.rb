# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::Root do
  let(:urn) { Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:en") }
  let(:metas) do
    {
      "caption" => "ISO 5598:2020(en)",
      "language" => "en",
      "titles" => { "en" => "Fluid power systems and components — Vocabulary" },
    }
  end

  describe "#content" do
    let(:doc) { described_class.new(urn:, metas:).content.doc }
    let(:root) { doc.at_css("standard") }

    it "renders dtd-version attribute" do
      expect(root["dtd-version"]).to eq("1.0")
    end

    it "declares xmlns:ali namespace" do
      expect(root.namespaces["xmlns:ali"]).to eq("http://www.niso.org/schemas/ali/1.0/")
    end

    it "declares xmlns:tbx namespace" do
      expect(root.namespaces["xmlns:tbx"]).to eq("urn:iso:std:iso:30042:ed-2")
    end

    it "declares xmlns:xlink namespace" do
      expect(root.namespaces["xmlns:xlink"]).to eq("http://www.w3.org/1999/xlink")
    end

    it "renders std-meta-type as international" do
      meta = doc.at_css("std-meta")
      expect(meta["std-meta-type"]).to eq("international")
    end

    it "renders std-ident block" do
      ident = doc.at_css("std-ident")
      expect(ident.at_css("originator").text).to eq("ISO")
      expect(ident.at_css("doc-type").text).to eq("IS")
      expect(ident.at_css("doc-number").text).to eq("5598")
      expect(ident.at_css("edition").text).to eq("3")
      expect(ident.at_css("version").text).to eq("1")
    end

    it "renders self-uri with URN" do
      expect(doc.at_css("self-uri").text).to eq("iso:std:iso:5598:ed-3:v1:en")
    end

    it "renders copyright-year from caption" do
      expect(doc.at_css("copyright-year").text).to eq("2020")
    end

    it "places permissions last in std-meta" do
      meta = doc.at_css("std-meta")
      last_element = meta.children.select(&:element?).last
      expect(last_element.name).to eq("permissions")
    end

    it "renders release-version" do
      expect(doc.at_css("release-version").text).to eq("IS")
    end
  end

  describe "doc-type inference" do
    it "returns TS for technical specification URN" do
      ts_urn = Obp::Access::Urn.new("iso:std:iso:ts:14812:ed-2:v1:en")
      root = described_class.new(urn: ts_urn, metas:)
      doc = root.content.doc
      expect(doc.at_css("doc-type").text).to eq("TS")
    end
  end
end

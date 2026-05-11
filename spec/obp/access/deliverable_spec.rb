# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Deliverable do
  let(:is_data) do
    {
      "id" => 123,
      "reference" => "ISO 9001:2015",
      "deliverableType" => "IS",
      "edition" => 5,
      "currentStage" => 6060,
      "languages" => %w[en fr],
      "supplementType" => nil,
      "title" => { "en" => "Quality management systems", "fr" => "Systèmes de management de la qualité" },
      "publicationDate" => "2015-09-15",
      "icsCode" => ["03.120.10"],
      "ownerCommittee" => "ISO/TC 176/SC 2",
    }
  end

  let(:ts_data) do
    {
      "id" => 456,
      "reference" => "ISO/TS 14812:2025",
      "deliverableType" => "TS",
      "edition" => 2,
      "currentStage" => 6060,
      "languages" => ["en"],
      "supplementType" => nil,
      "title" => { "en" => "Intelligent transport systems" },
      "publicationDate" => "2025-01-15",
      "icsCode" => ["03.220.01"],
      "ownerCommittee" => "ISO/TC 204",
    }
  end

  let(:dual_logo_data) do
    {
      "id" => 789,
      "reference" => "ISO/IEC 27001:2022",
      "deliverableType" => "IS",
      "edition" => 3,
      "currentStage" => 6060,
      "languages" => %w[en fr],
      "supplementType" => nil,
      "title" => { "en" => "Information security management systems" },
      "publicationDate" => "2022-10-25",
      "icsCode" => ["35.030"],
      "ownerCommittee" => "ISO/IEC JTC 1/SC 27",
    }
  end

  let(:part_data) do
    {
      "id" => 321,
      "reference" => "ISO 9000-2:1993",
      "deliverableType" => "IS",
      "edition" => 1,
      "currentStage" => 9599,
      "languages" => %w[en fr],
      "supplementType" => nil,
      "title" => { "en" => "Quality management — Part 2" },
      "publicationDate" => "1993-06-03",
      "icsCode" => %w[03.120.10 03.100.70],
      "ownerCommittee" => "ISO/TC 176/SC 2",
    }
  end

  let(:supplement_data) do
    {
      "id" => 999,
      "reference" => "ISO 9001:2015/Amd 1:2024",
      "deliverableType" => "IS",
      "edition" => 5,
      "currentStage" => 6060,
      "languages" => %w[en fr],
      "supplementType" => "Amd",
      "title" => { "en" => "Amendment 1" },
      "publicationDate" => "2024-02-01",
      "icsCode" => ["03.120.10"],
      "ownerCommittee" => "ISO/TC 176/SC 2",
    }
  end

  describe "attribute readers" do
    subject(:d) { described_class.new(is_data) }

    it "exposes all fields" do
      expect(d.id).to eq(123)
      expect(d.reference).to eq("ISO 9001:2015")
      expect(d.deliverable_type).to eq("IS")
      expect(d.edition).to eq(5)
      expect(d.current_stage).to eq(6060)
      expect(d.languages).to eq(%w[en fr])
      expect(d.supplement_type).to be_nil
      expect(d.title).to eq({ "en" => "Quality management systems", "fr" => "Systèmes de management de la qualité" })
      expect(d.publication_date).to eq("2015-09-15")
      expect(d.ics_codes).to eq(["03.120.10"])
      expect(d.owner_committee).to eq("ISO/TC 176/SC 2")
    end
  end

  describe "#english_title" do
    it "returns the English title" do
      d = described_class.new(is_data)
      expect(d.english_title).to eq("Quality management systems")
    end
  end

  describe "#published?" do
    it "returns true for stage 6060" do
      expect(described_class.new(is_data)).to be_published
    end

    it "returns true for stage 9092" do
      data = is_data.merge("currentStage" => 9092)
      expect(described_class.new(data)).to be_published
    end

    it "returns false for stage 9599 (withdrawn)" do
      expect(described_class.new(part_data)).not_to be_published
    end
  end

  describe "#base_document?" do
    it "returns true when supplement_type is nil" do
      expect(described_class.new(is_data)).to be_base_document
    end

    it "returns false when supplement_type is present" do
      expect(described_class.new(supplement_data)).not_to be_base_document
    end
  end

  describe "#retrievable?" do
    it "returns true when published, base document, and has languages" do
      expect(described_class.new(is_data)).to be_retrievable
    end

    it "returns false when withdrawn" do
      expect(described_class.new(part_data)).not_to be_retrievable
    end

    it "returns false when supplement" do
      expect(described_class.new(supplement_data)).not_to be_retrievable
    end

    it "returns false when no languages" do
      data = is_data.merge("languages" => [])
      expect(described_class.new(data)).not_to be_retrievable
    end
  end

  describe "#to_urn" do
    it "generates correct URN for plain ISO IS" do
      urn = described_class.new(is_data).to_urn
      expect(urn.to_s).to eq("iso:std:iso:9001:ed-5:v1:en")
    end

    it "generates correct URN for ISO/TS" do
      urn = described_class.new(ts_data).to_urn
      expect(urn.to_s).to eq("iso:std:iso:ts:14812:ed-2:v1:en")
    end

    it "generates correct URN for dual-logo (ISO/IEC)" do
      urn = described_class.new(dual_logo_data).to_urn
      expect(urn.to_s).to eq("iso:std:iso-iec:27001:ed-3:v1:en")
    end

    it "generates correct URN for document with part number" do
      urn = described_class.new(part_data).to_urn
      expect(urn.to_s).to eq("iso:std:iso:9000:-2:ed-1:v1:en")
    end

    it "generates correct URN for alternative language" do
      urn = described_class.new(is_data).to_urn(language: "fr")
      expect(urn.to_s).to eq("iso:std:iso:9001:ed-5:v1:fr")
    end

    it "strips supplement suffix from reference for URN generation" do
      urn = described_class.new(supplement_data).to_urn
      expect(urn.to_s).to eq("iso:std:iso:9001:ed-5:v1:en")
    end

    it "returns a Urn instance" do
      urn = described_class.new(is_data).to_urn
      expect(urn).to be_a(Obp::Access::Urn)
    end
  end

  describe "edge cases" do
    it "handles missing title gracefully" do
      data = is_data.merge("title" => nil)
      d = described_class.new(data)
      expect(d.title).to eq({})
      expect(d.english_title).to be_nil
    end

    it "handles missing languages gracefully" do
      data = is_data.merge("languages" => nil)
      d = described_class.new(data)
      expect(d.languages).to eq([])
    end

    it "handles missing icsCode gracefully" do
      data = is_data.merge("icsCode" => nil)
      d = described_class.new(data)
      expect(d.ics_codes).to eq([])
    end
  end
end

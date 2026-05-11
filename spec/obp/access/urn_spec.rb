# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Urn do
  describe "#initialize" do
    it "parses language and base from raw URN" do
      urn = described_class.new("iso:std:iso:ts:14812:ed-2:v1:en")

      expect(urn.raw).to eq("iso:std:iso:ts:14812:ed-2:v1:en")
      expect(urn.language).to eq("en")
      expect(urn.base).to eq("iso:std:iso:ts:14812:ed-2:v1")
    end

    it "handles single-segment URN" do
      urn = described_class.new("en")

      expect(urn.language).to eq("en")
      expect(urn.base).to eq("")
    end
  end

  describe "#safe" do
    it "replaces colons with dashes" do
      urn = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      expect(urn.safe).to eq("iso-std-iso-9001-ed-5-v1-en")
    end
  end

  describe "#to_s" do
    it "returns raw URN" do
      urn = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      expect(urn.to_s).to eq("iso:std:iso:9001:ed-5:v1:en")
    end
  end

  describe "equality" do
    it "considers same URN equal" do
      a = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      b = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      expect(a).to eq(b)
    end

    it "considers different URNs unequal" do
      a = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      b = described_class.new("iso:std:iso:9001:ed-5:v1:fr")
      expect(a).not_to eq(b)
    end

    it "hashes equal URNs to same value" do
      a = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      b = described_class.new("iso:std:iso:9001:ed-5:v1:en")
      expect(a.hash).to eq(b.hash)
    end
  end
end

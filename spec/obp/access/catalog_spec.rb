# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Catalog do
  let(:jsonl_content) do
    <<~JSONL
      {"id":1,"deliverableType":"IS","supplementType":null,"reference":"ISO 9001:2015","edition":5,"currentStage":6060,"languages":["en","fr"],"title":{"en":"Quality"},"publicationDate":"2015-09-15","icsCode":["03.120.10"],"ownerCommittee":"ISO/TC 176/SC 2"}
      {"id":2,"deliverableType":"TS","supplementType":null,"reference":"ISO/TS 14812:2025","edition":2,"currentStage":6060,"languages":["en"],"title":{"en":"ITS vocab"},"publicationDate":"2025-01-15","icsCode":["03.220.01"],"ownerCommittee":"ISO/TC 204"}
      {"id":3,"deliverableType":"IS","supplementType":null,"reference":"ISO 3590:1976","edition":1,"currentStage":9020,"languages":["en","fr"],"title":{"en":"Withdrawn"},"publicationDate":"1976-04-01","icsCode":["25.060.10"],"ownerCommittee":"ISO/TC 39"}
      {"id":4,"deliverableType":"IS","supplementType":"Amd","reference":"ISO 9001:2015/Amd 1:2024","edition":5,"currentStage":6060,"languages":["en"],"title":{"en":"Amd"},"publicationDate":"2024-02-01","icsCode":["03.120.10"],"ownerCommittee":"ISO/TC 176/SC 2"}
      {"id":5,"deliverableType":"IS","supplementType":null,"reference":"ISO 1000:1975","edition":1,"currentStage":6060,"languages":[],"title":{"en":"No langs"},"publicationDate":"1975-01-01","icsCode":[],"ownerCommittee":"ISO/TC 12"}
    JSONL
  end

  let(:tmpfile) do
    file = Tempfile.new(["catalog", ".jsonl"])
    file.write(jsonl_content)
    file.close
    file
  end

  after { tmpfile.unlink }

  describe ".load" do
    it "loads from a local JSONL file" do
      catalog = described_class.load(path: tmpfile.path)
      expect(catalog.count).to eq(5)
    end

    it "creates Deliverable objects" do
      catalog = described_class.load(path: tmpfile.path)
      catalog.deliverables.each do |d|
        expect(d).to be_a(Obp::Access::Deliverable)
      end
    end

    it "skips empty lines" do
      file = Tempfile.new(["catalog_empty", ".jsonl"])
      file.write("\n#{jsonl_content.lines.first}\n\n")
      file.close
      catalog = described_class.load(path: file.path)
      expect(catalog.count).to eq(1)
      file.unlink
    end
  end

  describe "#retrievable" do
    it "returns only published base documents with languages" do
      catalog = described_class.load(path: tmpfile.path)
      retrievable = catalog.retrievable

      refs = retrievable.map(&:reference)
      expect(refs).to include("ISO 9001:2015", "ISO/TS 14812:2025")
      expect(refs).not_to include("ISO 3590:1976") # stage 9020 (not published)
      expect(refs).not_to include("ISO 9001:2015/Amd 1:2024") # supplement
      expect(refs).not_to include("ISO 1000:1975") # no languages
    end
  end

  describe "#by_type" do
    it "filters by deliverable type" do
      catalog = described_class.load(path: tmpfile.path)
      ts = catalog.by_type("TS")
      expect(ts.size).to eq(1)
      expect(ts.first.reference).to eq("ISO/TS 14812:2025")
    end
  end

  describe "#by_ics" do
    it "filters by ICS code" do
      catalog = described_class.load(path: tmpfile.path)
      result = catalog.by_ics("03.120.10")
      expect(result.size).to eq(2)
      refs = result.map(&:reference)
      expect(refs).to include("ISO 9001:2015", "ISO 9001:2015/Amd 1:2024")
    end
  end

  describe "#count" do
    it "returns total number of deliverables" do
      catalog = described_class.load(path: tmpfile.path)
      expect(catalog.count).to eq(5)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Retriever do
  let(:deliverables) do
    [
      Obp::Access::Deliverable.new(
        "id" => 1,
        "deliverableType" => "IS",
        "supplementType" => nil,
        "reference" => "ISO 9001:2015",
        "edition" => 5,
        "currentStage" => 6060,
        "languages" => %w[en],
        "title" => { "en" => "Quality" },
        "publicationDate" => "2015-09-15",
        "icsCode" => ["03.120.10"],
        "ownerCommittee" => "ISO/TC 176/SC 2",
      ),
    ]
  end

  let(:catalog) do
    double(retrievable: deliverables)
  end

  let(:output_dir) { Dir.mktmpdir("retriever-test") }

  after { FileUtils.rm_rf(output_dir) }

  describe "#run" do
    it "creates output directory" do
      new_dir = File.join(output_dir, "nested")
      retriever = described_class.new(output_dir: new_dir, catalog:)
      allow(Obp::Access).to receive(:fetch).and_return(
        double(to_xml: "<standard/>", urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en")),
      )

      retriever.run
      expect(Dir.exist?(new_dir)).to be true
    end

    it "skips already-fetched deliverables" do
      manifest = { "1" => { "reference" => "ISO 9001:2015", "status" => "success" } }
      File.write(File.join(output_dir, "manifest.json"), JSON.generate(manifest))

      retriever = described_class.new(output_dir:, catalog:)
      retriever.run

      expect(File.read(File.join(output_dir, "manifest.json"))).to include("success")
    end

    it "writes manifest with success on fetch" do
      access_instance = double(
        to_xml: "<?xml version=\"1.0\"?>\n<standard/>",
        urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en"),
      )

      allow(Obp::Access).to receive(:fetch).with("iso:std:iso:9001:ed-5:v1:en").and_return(access_instance)

      retriever = described_class.new(output_dir:, catalog:, concurrency: 1)
      retriever.run

      manifest = JSON.parse(File.read(File.join(output_dir, "manifest.json")))
      expect(manifest["1"]["status"]).to eq("success")
      expect(manifest["1"]["reference"]).to eq("ISO 9001:2015")
    end

    it "writes manifest with failure on error" do
      allow(Obp::Access).to receive(:fetch).and_raise("OBP content not found")

      retriever = described_class.new(output_dir:, catalog:, concurrency: 1)
      retriever.run

      manifest = JSON.parse(File.read(File.join(output_dir, "manifest.json")))
      expect(manifest["1"]["status"]).to eq("failed")
      expect(manifest["1"]["error"]).to eq("OBP content not found")
    end

    it "saves XML files per language" do
      multi_lang_data = {
        "id" => 2,
        "deliverableType" => "IS",
        "supplementType" => nil,
        "reference" => "ISO 1000:1975",
        "edition" => 1,
        "currentStage" => 6060,
        "languages" => %w[en fr],
        "title" => { "en" => "Units", "fr" => "Unités" },
        "publicationDate" => "1975-01-01",
        "icsCode" => [],
        "ownerCommittee" => "ISO/TC 12",
      }
      multi_catalog = double(retrievable: [Obp::Access::Deliverable.new(multi_lang_data)])

      allow(Obp::Access).to receive(:fetch) do |urn|
        urn_obj = Obp::Access::Urn.new(urn)
        double(
          to_xml: "<?xml version=\"1.0\"?>\n<standard lang=\"#{urn_obj.language}\"/>",
          urn: urn_obj,
        )
      end

      retriever = described_class.new(output_dir:, catalog: multi_catalog, concurrency: 1)
      retriever.run

      dir = File.join(output_dir, "ISO-1000-1975")
      expect(File.exist?(File.join(dir, "en.xml"))).to be true
      expect(File.exist?(File.join(dir, "fr.xml"))).to be true
    end
  end
end

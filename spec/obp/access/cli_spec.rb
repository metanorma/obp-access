# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::CLI do
  subject(:cli) { described_class.new }

  describe "commands" do
    it "has fetch command" do
      expect(described_class.all_commands).to have_key("fetch")
    end

    it "has catalog command" do
      expect(described_class.all_commands).to have_key("catalog")
    end

    it "has retrieve command" do
      expect(described_class.all_commands).to have_key("retrieve")
    end
  end

  describe "#fetch" do
    it "outputs XML to stdout" do
      access_instance = double(
        to_xml: "<?xml version=\"1.0\"?>\n<standard/>",
        urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en"),
      )

      allow(Obp::Access).to receive(:fetch)
        .with("iso:std:iso:9001:ed-5:v1:en")
        .and_return(access_instance)

      expect { cli.fetch("iso:std:iso:9001:ed-5:v1:en") }.to output(/<standard/).to_stdout
    end

    it "saves XML to file when --output given" do
      dir = Dir.mktmpdir("cli-test")
      begin
        access_instance = double(
          to_xml: "<?xml version=\"1.0\"?>\n<standard/>",
          urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en"),
        )

        allow(Obp::Access).to receive(:fetch).and_return(access_instance)

        cli_with_output = described_class.new([], { "output" => dir })
        cli_with_output.fetch("iso:std:iso:9001:ed-5:v1:en")

        expect(File.exist?(File.join(dir, "iso-std-iso-9001-ed-5-v1-en.xml"))).to be true
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "fetches multiple languages as separate files" do
      dir = Dir.mktmpdir("cli-test")
      begin
        en_access = double(
          to_xml: "<?xml version=\"1.0\"?>\n<standard lang='en'/>",
          urn: Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:en"),
        )
        fr_access = double(
          to_xml: "<?xml version=\"1.0\"?>\n<standard lang='fr'/>",
          urn: Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:fr"),
        )
        de_access = double(
          to_xml: "<?xml version=\"1.0\"?>\n<standard lang='de'/>",
          urn: Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:de"),
        )

        allow(Obp::Access).to receive(:fetch_all)
          .with("iso:std:iso:5598:ed-3:v1:en", languages: :all)
          .and_return([en_access, fr_access, de_access])

        cli_with_output = described_class.new([], { "output" => dir, "languages" => "all" })
        cli_with_output.fetch("iso:std:iso:5598:ed-3:v1:en")

        expect(File.exist?(File.join(dir, "iso-std-iso-5598-ed-3-v1-en.xml"))).to be true
        expect(File.exist?(File.join(dir, "iso-std-iso-5598-ed-3-v1-fr.xml"))).to be true
        expect(File.exist?(File.join(dir, "iso-std-iso-5598-ed-3-v1-de.xml"))).to be true
      ensure
        FileUtils.rm_rf(dir)
      end
    end

    it "exits with error on failure" do
      allow(Obp::Access).to receive(:fetch).and_raise("OBP content not found")

      expect { cli.fetch("iso:std:iso:9999:ed-1:v1:en") }.to raise_error(SystemExit)
    end
  end

  describe "#catalog" do
    it "shows catalog summary" do
      catalog_instance = double(deliverables: [], retrievable: [])
      allow(Obp::Access::Catalog).to receive(:load).and_return(catalog_instance)

      expect { cli.catalog }.to output(/Total: 0/).to_stdout
    end
  end
end

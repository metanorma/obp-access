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
      access_instance = instance_double(Obp::Access,
                                        to_xml: "<?xml version=\"1.0\"?>\n<standard/>",
                                        urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en"))

      allow(Obp::Access).to receive(:fetch)
        .with("iso:std:iso:9001:ed-5:v1:en", languages: nil)
        .and_return(access_instance)

      expect { cli.fetch("iso:std:iso:9001:ed-5:v1:en") }.to output(/<standard/).to_stdout
    end

    it "saves XML to file when --output given" do
      dir = Dir.mktmpdir("cli-test")
      begin
        access_instance = instance_double(Obp::Access,
                                          to_xml: "<?xml version=\"1.0\"?>\n<standard/>",
                                          urn: Obp::Access::Urn.new("iso:std:iso:9001:ed-5:v1:en"))

        allow(Obp::Access).to receive(:fetch).and_return(access_instance)

        cli_with_output = described_class.new([], { "output" => dir })
        cli_with_output.fetch("iso:std:iso:9001:ed-5:v1:en")

        expect(File.exist?(File.join(dir, "iso-std-iso-9001-ed-5-v1-en.xml"))).to be true
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
      catalog_instance = instance_double(Obp::Access::Catalog)
      allow(catalog_instance).to receive(:deliverables).and_return([])
      allow(catalog_instance).to receive(:retrievable).and_return([])
      allow(Obp::Access::Catalog).to receive(:load).and_return(catalog_instance)

      expect { cli.catalog }.to output(/Total: 0/).to_stdout
    end
  end
end

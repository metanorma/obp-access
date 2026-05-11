# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access do
  describe ".fetch" do
    it "accepts a languages option" do
      urn = "iso:std:iso:5598:ed-3:v1:en"
      parser = instance_double(Obp::Access::Parser,
                               to_xml: "<standard/>",
                               html: "<html/>",
                               available_languages: %w[fr de],
                               title: "ISO 5598")
      allow(Obp::Access::Parser).to receive(:new).and_return(parser)

      access = described_class.fetch(urn, languages: :all)
      expect(access).to be_a(described_class)
    end

    it "raises ArgumentError without URN" do
      expect { described_class.fetch(nil) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_sts" do
    it "returns a Sts::NisoSts::Standard" do
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <standard xmlns:xlink="http://www.w3.org/1999/xlink"
                  xmlns:mml="http://www.w3.org/1998/Math/MathML"
                  xmlns:tbx="urn:iso:std:iso:30042:ed-2">
          <front><std-meta><permissions>
            <copyright-statement>All rights reserved</copyright-statement>
            <copyright-holder>ISO</copyright-holder>
          </permissions>
          <title-wrap xml:lang="en"><full>Test Standard</full></title-wrap>
          <proj-id>ISO 5598</proj-id><content-language>en</content-language>
          <std-ref type="dated">ISO 5598:2020</std-ref>
          <std-ref type="undated">ISO 5598</std-ref>
          <doc-ref>ISO 5598:2020</doc-ref>
          </std-meta></front>
          <body><sec id="sec_1"><label>1</label></sec></body>
          <back/>
        </standard>
      XML

      access = described_class.send(:new, Obp::Access::Urn.new("iso:std:iso:5598:ed-3:v1:en"))
      allow(access).to receive(:primary_xml).and_return(xml)
      allow(access).to receive(:multilingual?).and_return(false)

      result = access.to_sts
      expect(result).to be_a(Sts::NisoSts::Standard)
      expect(result.body.sec.size).to eq(1)
    end
  end
end

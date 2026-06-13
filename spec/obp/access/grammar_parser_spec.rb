# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::GrammarParser do
  describe ".parse" do
    it "extracts a plain noun term" do
      result = described_class.parse("pump")
      expect(result.term).to eq("pump")
      expect(result.pos).to eq("noun")
      expect(result.genders).to eq([])
    end

    it "extracts an adjective term" do
      result = described_class.parse("<b>adj.</b> hydraulic")
      expect(result.term).to eq("hydraulic")
      expect(result.pos).to eq("adjective")
    end

    it "extracts uppercase Adj. as adjective" do
      result = described_class.parse("<b>Adj.</b> hydraulisch")
      expect(result.term).to eq("hydraulisch")
      expect(result.pos).to eq("adjective")
    end

    it "extracts a verb term" do
      result = described_class.parse("<b>verb</b> to pump")
      expect(result.term).to eq("to pump")
      expect(result.pos).to eq("verb")
    end

    it "extracts a single gender" do
      result = described_class.parse("<b>m</b> Kolben")
      expect(result.term).to eq("Kolben")
      expect(result.genders).to eq(["masculine"])
    end

    it "extracts feminine gender" do
      result = described_class.parse("<b>f</b> pompe")
      expect(result.term).to eq("pompe")
      expect(result.genders).to eq(["feminine"])
    end

    it "extracts neuter gender" do
      result = described_class.parse("<b>n</b> Ventil")
      expect(result.term).to eq("Ventil")
      expect(result.genders).to eq(["neuter"])
    end

    it "extracts gender with trailing comma" do
      result = described_class.parse("<b>m,</b> <b>f</b> druck")
      expect(result.genders).to eq(%w[masculine feminine])
    end

    it "extracts multiple genders in one bold tag" do
      result = described_class.parse("<b>m, n</b> Gehäuse")
      expect(result.term).to eq("Gehäuse")
      expect(result.genders).to eq(%w[masculine neuter])
    end

    it "extracts gender with qualifier text" do
      result = described_class.parse("<b>m normal</b> Druck")
      expect(result.term).to eq("Druck")
      expect(result.genders).to eq(["masculine"])
    end

    it "extracts gender from term_with_gender pattern" do
      result = described_class.parse("<b>Zustand, m</b>")
      expect(result.term).to eq("Zustand")
      expect(result.genders).to eq(["masculine"])
    end

    it "deduplicates genders" do
      result = described_class.parse("<b>m</b> <b>m</b> Kolben")
      expect(result.genders).to eq(["masculine"])
    end

    it "handles bold term text (not grammar)" do
      result = described_class.parse("<b>hydraulic pump</b>")
      expect(result.term).to eq("hydraulic pump")
      expect(result.pos).to eq("noun")
      expect(result.genders).to eq([])
    end

    it "handles angle brackets to skip content" do
      result = described_class.parse("<b>〈</b>singular<b>〉</b> Pumpe")
      expect(result.term).to eq("Pumpe")
    end

    it "handles comma in bold as skip" do
      result = described_class.parse("Pumpe<b>,</b> <b>f</b>")
      expect(result.term).to eq("Pumpe")
      expect(result.genders).to eq(["feminine"])
    end

    it "combines POS and gender" do
      result = described_class.parse("<b>adj.</b> <b>m</b> hydraulischer")
      expect(result.term).to eq("hydraulischer")
      expect(result.pos).to eq("adjective")
      expect(result.genders).to eq(["masculine"])
    end

    it "combines POS and multiple genders" do
      result = described_class.parse("<b>adj.</b> <b>m, f</b> pompe hydraulique")
      expect(result.term).to eq("pompe hydraulique")
      expect(result.pos).to eq("adjective")
      expect(result.genders).to eq(%w[masculine feminine])
    end

    it "strips trailing commas from term" do
      result = described_class.parse("pump,")
      expect(result.term).to eq("pump")
    end

    it "normalizes whitespace in term" do
      result = described_class.parse("hydraulic   pump")
      expect(result.term).to eq("hydraulic pump")
    end

    it "returns a Result struct" do
      result = described_class.parse("pump")
      expect(result).to be_a(Struct)
      expect(result.members).to eq(%i[term pos genders])
    end
  end

  describe "GENDER_MAP" do
    it "maps HTML short codes to NISO STS grammaticalGender values" do
      expect(described_class::GENDER_MAP).to eq(
        "m" => "masculine",
        "f" => "feminine",
        "n" => "neuter",
      )
    end
  end
end

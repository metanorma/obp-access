# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::SectionType do
  describe ".for" do
    it "returns 'scope' for section 1" do
      expect(described_class.for("1")).to eq("scope")
    end

    it "returns 'norm-refs' for section 2" do
      expect(described_class.for("2")).to eq("norm-refs")
    end

    it "returns 'terms' for section 3" do
      expect(described_class.for("3")).to eq("terms")
    end

    it "returns 'terms' for section 10" do
      expect(described_class.for("10")).to eq("terms")
    end

    it "returns 'terms' for sub-section 3.1" do
      expect(described_class.for("3.1")).to eq("terms")
    end

    it "returns 'terms' for sub-section 4.2" do
      expect(described_class.for("4.2")).to eq("terms")
    end

    it "returns nil for front section 'foreword'" do
      expect(described_class.for("foreword")).to be_nil
    end

    it "returns nil for front section 'intro'" do
      expect(described_class.for("intro")).to be_nil
    end
  end
end

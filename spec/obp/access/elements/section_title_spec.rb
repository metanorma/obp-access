# frozen_string_literal: true

require "spec_helper"

RSpec.describe Obp::Access::Renderer::Elements::SectionTitle do
  describe "#label" do
    it "extracts numeric label from body section" do
      expect(described_class.new("1   Scope").label).to eq("1")
    end

    it "extracts dotted label from sub-section" do
      expect(described_class.new("3.1   Terms related to general concepts").label).to eq("3.1")
    end

    it "extracts multi-level dotted label" do
      expect(described_class.new("3.1.2   Deep sub-section").label).to eq("3.1.2")
    end

    it "returns nil for front section without number" do
      expect(described_class.new("Foreword").label).to be_nil
    end

    it "returns nil for Introduction" do
      expect(described_class.new("Introduction").label).to be_nil
    end
  end

  describe "#text" do
    it "strips label prefix from body section" do
      expect(described_class.new("1   Scope").text).to eq("Scope")
    end

    it "strips label prefix from sub-section" do
      title = described_class.new("3.1   Terms related to general concepts")
      expect(title.text).to eq("Terms related to general concepts")
    end

    it "returns full text for front section" do
      expect(described_class.new("Foreword").text).to eq("Foreword")
    end

    it "returns Normative references text" do
      expect(described_class.new("2   Normative references").text).to eq("Normative references")
    end

    it "handles single space between number and text" do
      expect(described_class.new("5 Terms").label).to be_nil
      expect(described_class.new("5 Terms").text).to eq("5 Terms")
    end
  end
end

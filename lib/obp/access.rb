require "obp/access/parser"
require "obp/access/converter"
require "obp/access/rendered"
require "obp/access/version"

module Obp
  module Access
    def self.fetch(urn = nil)
      raise ArgumentError.new("URN is required. Please pass it as an argument") unless urn

      Obp::Access::Parser.new(urn)
    end
  end
end

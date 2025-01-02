require "obp/access/parser"
require "obp/access/converter"
require "obp/access/renderer"
require "obp/access/version"

module Obp
  class Access
    BASE_URL = "https://www.iso.org".freeze
    API_URL = "#{BASE_URL}/obp/ui".freeze

    attr_reader :urn

    def self.fetch(urn = nil)
      raise ArgumentError.new("URN is required. Please pass it as an argument") unless urn

      Obp::Access.new(urn)
    end

    def initialize(urn)
      @urn = urn
    end

    def to_xml(pretty: false)
      pretty ? pretty_print_xml : xml
    end

    def to_sts
      Sts::NisoSts::Standard.from_xml(xml)
    end

    def to_xml_file
      file_path = File.join(tmpdir, "#{urn_safe}.xml")
      File.write(file_path, pretty_print_xml)
      file_path
    end

    private

    def parser
      @parser ||= Obp::Access::Parser.new(urn:, directory: tmpdir)
    end

    def xml
      parser.to_xml
    end

    def pretty_print_xml
      doc = Nokogiri::XML(xml, &:noblanks)
      doc.to_xml
    end

    def tmpdir
      @tmpdir ||= Dir.mktmpdir(urn_safe)
    end

    def urn_safe
      @urn_safe ||= urn.tr(":", "-") # Convert urn : to - for non-unix system compatibility
    end
  end
end

require "tmpdir"
require "net/http"
require "nokogiri"
require "json"
require "lutaml/model"
require "sts"
require "parallel"

require_relative "access/urn"
require_relative "access/inline_renderer"
require_relative "access/grammar_parser"
require_relative "access/domain_extractor"
require_relative "access/multilingual_merger"
require_relative "access/deliverable"
require_relative "access/catalog"
require_relative "access/retriever"
require_relative "access/fetcher"
require_relative "access/element_registry"
require_relative "access/parser"
require_relative "access/converter"
require_relative "access/imager"
require_relative "access/renderer"
require_relative "access/cli"

require_relative "access/elements/base"
require_relative "access/elements/root"
require_relative "access/elements/introduction"
require_relative "access/elements/index"
require_relative "access/elements/section"
require_relative "access/elements/figure"
require_relative "access/elements/figure_group"
require_relative "access/elements/list"
require_relative "access/elements/array"
require_relative "access/elements/table_wrap"
require_relative "access/elements/title"
require_relative "access/elements/paragraph"
require_relative "access/elements/non_normative_note"
require_relative "access/elements/copyright"
require_relative "access/elements/bibliography"
require_relative "access/elements/terminology"
require_relative "access/elements/terminology/base"
require_relative "access/elements/terminology/definition"
require_relative "access/elements/terminology/note"
require_relative "access/elements/terminology/tig"
require_relative "access/elements/terminology/tig_admitted"
require_relative "access/elements/terminology/tig_preferred"
require_relative "access/elements/terminology/tig_deprecated"
require_relative "access/elements/terminology/example"
require_relative "access/elements/terminology/source"
require_relative "access/version"

module Obp
  class Access
    BASE_URL = "https://www.iso.org".freeze
    API_URL = "#{BASE_URL}/obp/ui".freeze

    attr_reader :urn

    def self.fetch(urn, languages: nil)
      raise ArgumentError, "URN is required" unless urn

      new(Urn.new(urn), languages:)
    end

    def initialize(urn, languages: nil)
      @urn = urn
      @languages = languages
    end

    def to_xml(pretty: false)
      xml = primary_xml
      xml = merge_translations(xml) if multilingual?
      pretty ? pretty_print(xml) : xml
    end

    def to_sts
      Sts::NisoSts::Standard.from_xml(to_xml)
    end

    def to_xml_file
      path = File.join(tmpdir, "#{urn.safe}.xml")
      File.write(path, to_xml(pretty: true))
      path
    end

    private

    def primary_xml
      @primary_xml ||= parser.to_xml
    end

    def parser
      @parser ||= Parser.new(urn:, directory: tmpdir)
    end

    def multilingual?
      resolved_languages.size > 1
    end

    def resolved_languages
      @resolved_languages ||= begin
        available = parser.available_languages
        case @languages
        when nil then [urn.language]
        when :all then [urn.language] | available
        when Array then [urn.language] | (@languages & available)
        end
      end
    end

    def additional_languages
      resolved_languages - [urn.language]
    end

    def merge_translations(xml)
      document = Nokogiri::XML(xml)
      additional_sources = fetch_additional_sources
      MultilingualMerger.new(document, additional_sources, {}).merge
      document.to_xml
    end

    def fetch_additional_sources
      Parallel.map(additional_languages) do |lang|
        other_urn = Urn.new("#{urn.base}:#{lang}")
        other_parser = Parser.new(urn: other_urn, directory: tmpdir)
        [lang, other_parser.html]
      end.to_h
    end

    def pretty_print(xml)
      Nokogiri::XML(xml, &:noblanks).to_xml
    end

    def tmpdir
      @tmpdir ||= Dir.mktmpdir(urn.safe)
    end
  end
end

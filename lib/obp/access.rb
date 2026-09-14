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
require_relative "access/deliverable"
require_relative "access/catalog"
require_relative "access/retriever"
require_relative "access/fetcher"
require_relative "access/element_registry"
require_relative "access/parser"
require_relative "access/raw_html_parser"
require_relative "access/converter"
require_relative "access/imager"
require_relative "access/renderer"
require_relative "access/table_mapper"
require_relative "access/table_term_extractor"
require_relative "access/cli"

require_relative "access/elements/base"
require_relative "access/elements/root"
require_relative "access/elements/introduction"
require_relative "access/elements/index"
require_relative "access/elements/section_type"
require_relative "access/elements/section_title"
require_relative "access/elements/section"
require_relative "access/elements/figure"
require_relative "access/elements/figure_group"
require_relative "access/elements/list"
require_relative "access/elements/array"
require_relative "access/elements/table_wrap"
require_relative "access/elements/title"
require_relative "access/elements/paragraph"
require_relative "access/elements/non_normative_note"
require_relative "access/elements/non_normative_example"
require_relative "access/elements/disp_formula"
require_relative "access/elements/footnotes"
require_relative "access/elements/protected_content_note"
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

    def self.fetch(urn)
      raise ArgumentError, "URN is required" unless urn

      new(Urn.new(urn))
    end

    def self.fetch_all(urn, languages:)
      urn = Urn.new(urn)
      available = new(urn).available_languages
      resolved = resolve_languages(urn.language, languages, available)
      resolved.map { |lang| new(Urn.new("#{urn.base}:#{lang}")) }
    end

    # Build an Access from an already-downloaded OBP HTML fragment (e.g.
    # captured via a browser or waffle-punch). No network requests are made.
    def self.from_html(urn:, html:, caption: nil, titles: nil)
      raise ArgumentError, "URN is required" unless urn
      raise ArgumentError, "HTML is required" unless html

      new(Urn.new(urn), html: html, caption: caption, titles: titles)
    end

    def self.resolve_languages(primary, requested, available)
      case requested
      when :all then [primary] | available
      when Array then [primary] | (requested & available)
      else [primary]
      end
    end

    def initialize(urn, html: nil, caption: nil, titles: nil)
      @urn = urn
      @raw_html = html
      @caption = caption
      @raw_titles = titles
    end

    def to_xml(pretty: false)
      xml = parser.to_xml
      pretty ? pretty_print(xml) : xml
    end

    def to_sts
      Sts::NisoSts::Standard.from_xml(to_xml)
    end

    # YAML serialization of every table in the OBP preview HTML
    # (TableMapper's generic table model).
    def to_tables
      table_mapper.to_yaml
    end

    # YAML serialization of term entries extracted from the document's
    # term-carrying tables (TableTermExtractor over the table model).
    def to_terms
      TableTermExtractor.new(tables: table_mapper.tables).to_yaml
    end

    def to_xml_file
      path = File.join(tmpdir, "#{urn.safe}.xml")
      File.write(path, to_xml(pretty: true))
      path
    end

    def available_languages
      parser.available_languages
    end

    # Raw sts-standard HTML fragment as served by the OBP.
    def html
      parser.html
    end

    private

    def parser
      @parser ||= if @raw_html
                    RawHtmlParser.new(urn:, directory: tmpdir, html: @raw_html,
                                      caption: @caption, titles: @raw_titles)
                  else
                    Parser.new(urn:, directory: tmpdir)
                  end
    end

    # Shares Parser#html (memoized) with the STS conversion path, so
    # reading tables does not re-POST to the OBP.
    def table_mapper
      @table_mapper ||= TableMapper.new(source: parser.html)
    end

    def pretty_print(xml)
      Nokogiri::XML(xml, &:noblanks).to_xml
    end

    def tmpdir
      @tmpdir ||= Dir.mktmpdir(urn.safe)
    end
  end
end

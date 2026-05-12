# frozen_string_literal: true

require "thor"

module Obp
  class Access
    class CLI < Thor
      desc "fetch URN", "Fetch a single document from ISO OBP by URN"
      option :output, aliases: "-o", type: :string, desc: "Output directory (default: stdout)"
      option :languages, aliases: "-l", type: :string,
                         desc: "Languages: 'all' or comma-separated (e.g. 'fr,de')"
      def fetch(urn)
        langs = parse_languages
        if langs
          say "Fetching #{urn} (#{langs == :all ? 'all languages' : langs.join(', ')})..."
          Access.fetch_all(urn, languages: langs).each { |access| output(access) }
        else
          say "Fetching #{urn}..."
          output(Access.fetch(urn))
        end
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "catalog", "Load and inspect the ISO Open Data catalog"
      option :path, type: :string, desc: "Local JSONL file path (default: fetch remote)"
      option :filter, type: :string, enum: %w[retrievable types], desc: "Filter mode"
      option :type, type: :string, desc: "Filter by deliverable type (IS, TS, TR, etc.)"
      option :ics, type: :string, desc: "Filter by ICS code"
      def catalog
        say "Loading catalog..."
        cat = Access::Catalog.load(path: options[:path])

        if options[:filter] == "types"
          print_type_summary(cat)
          return
        end

        print_deliverables(cat)
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      desc "retrieve", "Bulk retrieve documents from ISO OBP"
      option :output, aliases: "-o", type: :string, required: true, desc: "Output directory"
      option :path, type: :string, desc: "Local JSONL file path"
      option :concurrency, aliases: "-c", type: :numeric, default: 4, desc: "Thread concurrency"
      def retrieve
        say "Loading catalog..."
        cat = Access::Catalog.load(path: options[:path])
        say "Found #{cat.retrievable.size} retrievable deliverables"
        build_retriever(cat).run
      rescue StandardError => e
        say "Error: #{e.message}", :red
        exit 1
      end

      private

      def output(access)
        if options[:output]
          dir = File.expand_path(options[:output])
          FileUtils.mkdir_p(dir)
          path = File.join(dir, "#{access.urn.safe}.xml")
          File.write(path, access.to_xml(pretty: true))
          say "Saved to #{path}", :green
        else
          puts access.to_xml(pretty: true)
        end
      end

      def print_deliverables(cat)
        filtered = apply_filters(cat)
        say "Total: #{filtered.size} deliverables"
        filtered.first(20).each do |d|
          say "  #{d.reference} [#{d.deliverable_type}] stage=#{d.current_stage} langs=#{d.languages.join(',')}"
        end
        say "  ... (showing first 20)" if filtered.size > 20
      end

      def apply_filters(cat)
        return cat.by_type(options[:type]) if options[:type]
        return cat.by_ics(options[:ics]) if options[:ics]
        return cat.retrievable if options[:filter] == "retrievable"

        cat.deliverables
      end

      def build_retriever(cat)
        Access::Retriever.new(
          output_dir: File.expand_path(options[:output]),
          catalog: cat,
          concurrency: options[:concurrency],
        )
      end

      def parse_languages
        case options[:languages]
        when nil then nil
        when "all" then :all
        else options[:languages].split(",").map(&:strip)
        end
      end

      def print_type_summary(cat)
        cat.deliverables.group_by(&:deliverable_type).sort.each do |type, list|
          published = list.count(&:published?)
          say "  #{type || 'IS'}: #{list.size} total, #{published} published"
        end
      end
    end
  end
end

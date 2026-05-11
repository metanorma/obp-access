# frozen_string_literal: true

require "json"
require "fileutils"

module Obp
  class Access
    class Retriever
      MANIFEST_FILE = "manifest.json"

      attr_reader :output_dir, :catalog, :concurrency

      def initialize(output_dir:, catalog:, concurrency: 4)
        @output_dir = output_dir
        @catalog = catalog
        @concurrency = concurrency
      end

      def run
        FileUtils.mkdir_p(output_dir)
        pending = pending_deliverables
        total = pending.size

        if total.zero?
          puts "Nothing to retrieve — all #{catalog.retrievable.size} deliverables already fetched."
          return
        end

        puts "Retrieving #{total} deliverables to #{output_dir} (concurrency: #{concurrency})..."
        process_all(pending, total)
        puts "Done. Fetched #{total} documents."
      end

      private

      def pending_deliverables
        catalog.retrievable.reject { |d| manifest.key?(d.id.to_s) }
      end

      def process_all(pending, total)
        Parallel.each_with_index(pending, in_threads: concurrency) do |deliverable, i|
          process_one(deliverable, i + 1, total)
        end
      end

      def process_one(deliverable, index, total)
        deliverable.languages.each { |lang| fetch_and_save(deliverable, lang) }
        record_success(deliverable)
        puts "[#{index}/#{total}] #{deliverable.reference} — OK"
      rescue StandardError => e
        record_failure(deliverable, e)
        puts "[#{index}/#{total}] #{deliverable.reference} — FAILED: #{e.message}"
      end

      def fetch_and_save(deliverable, language)
        urn = deliverable.to_urn(language:)
        access = Access.fetch(urn.to_s)
        xml = access.to_xml(pretty: true)

        dir = File.join(output_dir, deliverable.reference.gsub(%r{[/:\s]}, "-"))
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "#{language}.xml"), xml)
      end

      def record_success(deliverable)
        manifest[deliverable.id.to_s] = {
          "reference" => deliverable.reference,
          "status" => "success",
          "timestamp" => Time.now.utc.iso8601,
        }
        save_manifest
      end

      def record_failure(deliverable, error)
        manifest[deliverable.id.to_s] = {
          "reference" => deliverable.reference,
          "status" => "failed",
          "error" => error.message,
          "timestamp" => Time.now.utc.iso8601,
        }
        save_manifest
      end

      def manifest
        @manifest ||= begin
          path = File.join(output_dir, MANIFEST_FILE)
          File.exist?(path) ? JSON.parse(File.read(path)) : {}
        end
      end

      def save_manifest
        path = File.join(output_dir, MANIFEST_FILE)
        File.write(path, JSON.pretty_generate(manifest))
      end
    end
  end
end

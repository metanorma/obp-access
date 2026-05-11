# frozen_string_literal: true

require "json"
require "net/http"

module Obp
  class Access
    class Catalog
      SOURCE_URL = "https://isopublicstorageprod.blob.core.windows.net/opendata/" \
                   "_latest/iso_deliverables_metadata/json/iso_deliverables_metadata.jsonl"

      attr_reader :deliverables

      def initialize(deliverables:)
        @deliverables = deliverables
      end

      def self.load(path: nil, url: SOURCE_URL)
        raw = path ? read_local(path) : fetch_remote(url)
        new(deliverables: parse_jsonl(raw).map { |data| Deliverable.new(data) })
      end

      def retrievable
        @retrievable ||= deliverables.select(&:retrievable?)
      end

      def by_type(type)
        deliverables.select { |d| d.deliverable_type == type }
      end

      def by_ics(code)
        deliverables.select { |d| d.ics_codes.include?(code) }
      end

      def count
        deliverables.size
      end

      class << self
        private

        def parse_jsonl(text)
          text.lines.filter_map do |line|
            line.strip!
            next if line.empty?

            JSON.parse(line)
          end
        end

        def read_local(path)
          File.read(path)
        end

        def fetch_remote(url)
          uri = URI(url)
          response = Net::HTTP.get_response(uri)
          unless response.is_a?(Net::HTTPSuccess)
            raise "Failed to fetch catalog: #{response.code} #{response.message}"
          end

          response.body
        end
      end
    end
  end
end

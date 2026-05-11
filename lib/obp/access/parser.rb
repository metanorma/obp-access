module Obp
  class Access
    class Parser
      attr_reader :urn, :directory

      def initialize(urn:, directory:)
        @urn = urn
        @directory = directory
      end

      def to_xml
        xml
      end

      def title
        tab_data["description"]
      end

      def html
        @html ||= begin
          content = state.filter_map { |attr| attr["htmlContent"] }.first
          raise "OBP content not found for URN #{urn}" unless content

          content
        end
      end

      def available_languages
        state
          .select { |attr| !attr["caption"]&.empty? && attr["styles"]&.include?("toggle") }
          .filter_map { |attr| attr["caption"] }
          .uniq
      end

      private

      def fetcher
        @fetcher ||= Fetcher.new(urn:)
      end

      def state
        @state ||= fetcher.fetch_state
      end

      def xml
        @xml ||= begin
          metas = {
            "titles" => titles,
            "images" => images,
            "language" => urn.language,
          }.merge(tab_data)

          Converter.new(urn:, metas:, source: html).to_xml
        end
      end

      def tab_data
        @tab_data ||= state.filter_map { |attr| attr["tabs"] }.first.last
      end

      def titles
        languages = available_languages
        languages = [urn.language] if languages.empty?

        Parallel.map(languages) { |lang| fetch_title(lang) }.to_h
      end

      def fetch_title(lang)
        if lang == urn.language
          [lang, title]
        else
          other_urn = Urn.new("#{urn.base}:#{lang}")
          [lang, Parser.new(urn: other_urn, directory:).title]
        end
      end

      def images
        Imager.new(html:, directory:).images
      end
    end
  end
end

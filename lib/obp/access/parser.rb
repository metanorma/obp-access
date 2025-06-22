module Obp
  class Access
    class Parser
      attr_reader :urn, :directory, :language, :base_urn

      def initialize(urn:, directory:)
        @urn = urn
        @directory = directory
        @language = urn.split(":").last
        @base_urn = urn.split(":")[0...-1].join(":") # urn without the language part
      end

      def to_xml
        xml
      end

      def title
        state.filter_map { |attr| attr["tabs"] }.first.last["description"]
      end

      private

      def state
        @state ||= begin
          ui_response = load_ui_response
          ui_json     = JSON.parse(ui_response.body)
          state_json  = JSON.parse(ui_json["uidl"])

          state_json["state"].values
        end
      end

      def xml
        @xml ||= begin
          metas = {
            "titles" => titles,
            "images" => images,
            "language" => language,
          }
          metas.merge! state.filter_map { |attr| attr["tabs"] }.first.last
          converter = Converter.new(urn:, metas:, source: html)
          converter.to_xml
        end
      end

      def html
        @html ||= begin
          html = state.filter_map { |attr| attr["htmlContent"] }.first
          unless html
            raise StandardError,
                  "OBP can't by found using reference #{urn}."
          end

          html
        end
      end

      def titles
        languages = get_languages_from_html
        languages = [language] if languages.empty?

        # Parallelize translated titles fetching to speed up process
        Parallel.map(languages) do |key|
          if key == language
            [key, title]
          else
            [key, Parser.new(urn: "#{base_urn}:#{key}", directory:).title]
          end
        end.to_h
      end

      def images
        Imager.new(html:, directory:).images
      end

      def load_ui_response
        payload = {
          "v-browserDetails" => 1,
          "theme" => "iso-red",
          "v-loc" => "#{API_URL}##{urn}",
        }

        Net::HTTP.post_form(URI(API_URL), payload)
      end

      def get_languages_from_html
        state
          .select { |attr| !attr["caption"]&.empty? && attr["styles"]&.include?("toggle") }
          .map { |attr| attr["caption"] }.uniq
      end
    end
  end
end

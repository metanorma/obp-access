require "net/http"
require "nokogiri"
require "json"
require "sts"

module Obp
  module Access
    class Parser
      BASE_URL = "https://www.iso.org".freeze
      API_URL = "#{BASE_URL}/obp/ui".freeze

      IMAGE_FOLDER = "images".freeze

      attr_reader :urn, :language, :base_urn

      def initialize(urn)
        @urn = urn
        @language = urn.split(":").last
        @base_urn = urn.split(":")[0...-1].join(":")
      end

      def to_xml(pretty: false)
        pretty ? pretty_print_xml(xml) : xml
      end

      def to_sts
        Sts::NisoSts::Standard.from_xml(xml)
      end

      def to_xml_file
        file = Tempfile.new([urn, ".xml"])
        file.write(pretty_print_xml(xml))
        file.close
        file.path
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
        @xml ||= convert_html_to_xml
      end

      def html
        @html ||= begin
          html = state.filter_map { |attr| attr["htmlContent"] }.first
          raise StandardError, "OBP can't by found using reference #{urn}." unless html

          html
        end
      end

      def languages
        @languages ||= begin
          languages = get_languages_from_html
          languages.empty? ? [language] : languages
        end
      end

      def titles
        @titles ||= languages.to_h do |key|
          if key == language
            [key, title]
          else
            [key, Parser.new("#{base_urn}:#{key}").title]
          end
        end
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

      def convert_html_to_xml
        metas = state.filter_map { |attr| attr["tabs"] }.first.last
        metas["titles"] = titles
        metas["language"] = language
        converter = Converter.new(urn:, metas:, source: html)
        converter.to_xml
      end

      def pretty_print_xml(xml_content)
        doc = Nokogiri::XML(xml_content, &:noblanks)
        doc.to_xml
      end

      # def write_images_and_patch_links
      #   images = page.xpath("//div[contains(@class, 'sts-standard')]//img")
      #   images.each do |img|
      #     filename = File.basename(img["src"])
      #     subpath = "#{IMAGE_FOLDER}/#{filename}"
      #
      #     image_blob = load_image_blob(img["src"])
      #     File.write("#{options[:output]}/#{subpath}", image_blob, mode: "wb")
      #
      #     img["src"] = subpath
      #   end
      # end
      #
      # def load_image_blob(image_href)
      #   image_url = "#{BASE_URL}#{image_href}"
      #
      #   Net::HTTP.get_response(URI(image_url)).body
      # end
    end
  end
end

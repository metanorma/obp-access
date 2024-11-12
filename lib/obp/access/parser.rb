require "optparse"
require "net/http"
require "nokogiri"
require "json"
require "yaml"
require "fileutils"

module Obp
  module Access
    class Parser
      BASE_URL = "https://www.iso.org".freeze
      API_URL = "#{BASE_URL}/obp/ui".freeze

      IMAGE_FOLDER = "images".freeze

      attr_reader :options

      def self.start(options)
        new(options).start
      end

      def initialize(options)
        @options = options
      end

      def start
        @state = parse_state

        puts "[obp-access] writing output..."

        prepare_output_folders
        write_metadata
        write_images_and_patch_links
        write_page_html

        convert_html_to_xml

        puts "[obp-access] output written to `#{options[:output]}/`"
      end

      private

      def title
        @title ||= @state.filter_map do |attr|
          attr.dig("pageState", "title")
        end.first.split(",").last
      end

      def identifier
        @identifier ||= @state.detect do |attr|
          attr["styles"]&.first == "h2"
        end["text"]
      end

      def render_html(source_html)
        Nokogiri::HTML5::Document.parse <<-EOHTML
        <!DOCTYPE html>
        <html>
          <head>
            <title>#{identifier}: #{title}</title>
            <meta charset="UTF-8">
          </head>
          <body>
          #{source_html}
          </body>
        </html>
        EOHTML
      end

      def page
        @page ||= begin
          source_html = @state.filter_map { |attr| attr["htmlContent"] }.first
          render_html(source_html)
        end
      end

      def prepare_output_folders
        FileUtils.mkdir_p("#{options[:output]}/#{IMAGE_FOLDER}") # root folder will be created automatically
      end

      def write_metadata
        metadata = {
          "scrape_date" => Time.now.utc,
          "identifier" => identifier,
          "title" => title,
          "urn" => options[:urn],
        }.to_yaml

        File.write("#{options[:output]}/metadata.yml", metadata)
      end

      def write_images_and_patch_links
        images = page.xpath("//div[contains(@class, 'sts-standard')]//img")
        images.each do |img|
          filename = File.basename(img["src"])
          subpath = "#{IMAGE_FOLDER}/#{filename}"

          image_blob = load_image_blob(img["src"])
          File.write("#{options[:output]}/#{subpath}", image_blob, mode: "wb")

          img["src"] = subpath
        end
      end

      def write_page_html
        File.write("#{options[:output]}/index.html", page.to_html)
      end

      def parse_state
        ui_response = load_ui_response
        ui_json     = JSON.parse(ui_response.body)
        state_json  = JSON.parse(ui_json["uidl"])

        state_json["state"].values
      end

      def load_ui_response
        payload = {
          "v-browserDetails" => 1,
          "theme" => "iso-red",
          "v-loc" => "#{API_URL}##{options[:urn]}",
        }

        Net::HTTP.post_form(URI(API_URL), payload)
      end

      def load_image_blob(image_href)
        image_url = "#{BASE_URL}#{image_href}"

        Net::HTTP.get_response(URI(image_url)).body
      end

      def convert_html_to_xml
        html = @state.filter_map { |attr| attr["htmlContent"] }.first
        Converter.new(urn: options[:urn], source: html).to_xml
      end
    end
  end
end

require 'ferrum'
require 'open-uri'
require 'yaml'
require 'optparse'
require 'fileutils'
require 'nokogiri'

module Obp
  module Access
    class Parser
      BASE_URL = 'https://www.iso.org'.freeze
      PAGE_URL = "#{BASE_URL}/obp/ui#".freeze

      CONTENT_CLASS = 'sts-standard'.freeze
      TITLE_CLASS = 'std-title'.freeze
      IDENTIFIER_CLASS = 'v-label-h2'.freeze

      attr_reader :browser, :page, :options

      def self.start(options)
        new(options).start
      end

      def initialize(options)
        @browser = Ferrum::Browser.new
        @page = browser.create_page
        @options = options
      end

      def start
        open_page
        prepare_output_folders
        write_metadata
        write_images
        write_page_html
      end

      private

      def open_page
        page.go_to("#{PAGE_URL}#{options[:urn]}")
        wait_for('div.std-title', browser: browser)
      end

      def title
        @title ||= page.at_css(".#{TITLE_CLASS}").text
      end

      def identifier
        @identifier ||= page.at_css(".#{IDENTIFIER_CLASS}").text
      end

      def page_html
        @page_html ||= begin
          html = page.at_css(".#{CONTENT_CLASS}").evaluate('this.innerHTML')

          replace_image_paths(html)
        end
      end

      def write_metadata
        File.open("#{options[:output]}/metadata.yml", "w") do |f|
          data = {
            'scrape_date' => Time.now,
            'identifier' => identifier,
            'title' => title,
            'urn' => options[:urn]
          }.to_yaml

          f.write(data)
        end
      end

      def write_images
        images = page.xpath("//div[contains(@class, '#{CONTENT_CLASS}')]//img/@src")
        images.each do |img|
          filename = File.basename(img.value)

          File.open("#{options[:output]}/images/#{filename}", 'wb') do |file|
            file.write(URI.parse("#{BASE_URL}#{img.value}").open.read)
          end
        end
      end

      def write_page_html
        File.open("#{options[:output]}/index.html", 'w') do |file|
          file.write(page_html)
        end
      end

      def prepare_output_folders
        FileUtils.mkdir_p(options[:output])
        FileUtils.mkdir_p("#{options[:output]}/images")
      end

      def replace_image_paths(html)
        doc = Nokogiri::HTML(html)
        doc.css('img').each do |img|
          img['src'] = "images/#{File.basename(img['src'])}"
        end

        doc.to_html
      end

      def wait_for(want, browser:, wait: 1, step: 0.1)
        meth = want.start_with?('/') ? :at_xpath : :at_css
        until node = browser.public_send(meth, want)
          (wait -= step) > 0 ? sleep(step) : break
        end
        node
      end
    end
  end
end

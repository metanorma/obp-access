module Obp
  class Access
    class Imager
      attr_reader :html, :directory

      def initialize(html:, directory:)
        @html = html
        @directory = directory
      end

      def images
        doc = Nokogiri::HTML(html)
        images = doc.search("div.sts-fig > img").to_h do |img|
          key = img.attr("src")
          path = File.join(imgdir, key.split("/").last)
          [key, path]
        end
        download_images(images)
        images
      end

      private

      def imgdir
        @imgdir ||= FileUtils.mkdir(File.join(directory, "images")).first
      end

      def download_images(images)
        Parallel.each(images) { |key, path| download_image(key, path) }
      end

      def download_image(key, path)
        url = "#{BASE_URL}#{key}"
        blob = Net::HTTP.get_response(URI(url)).body
        File.write(path, blob, mode: "wb")
      end
    end
  end
end

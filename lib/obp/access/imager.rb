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
        # For now, only images in <fig> are supported
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

      # Parallelize images fetching to speed up process
      def download_images(images)
        Parallel.each(images) { |key, path| download_image(key, path) }
      end

      def download_image(key, path)
        url = "#{BASE_URL}#{key}"

        image_blob = Net::HTTP.get_response(URI(url)).body
        File.write(path, image_blob, mode: "wb")
      end
    end
  end
end

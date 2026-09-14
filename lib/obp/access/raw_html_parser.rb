module Obp
  class Access
    # Parser that converts an already-downloaded OBP HTML fragment (e.g.
    # captured via a browser / waffle-punch) without touching the network.
    # Duck-types with Parser for the Access pipeline.
    class RawHtmlParser < Parser
      def initialize(urn:, directory:, html:, caption: nil, titles: nil)
        super(urn:, directory:)
        @raw_html = html
        @caption = caption
        @raw_titles = titles
      end

      def html
        @raw_html
      end

      def available_languages
        [urn.language]
      end

      private

      def state
        raise "RawHtmlParser does not fetch OBP state"
      end

      def tab_data
        { "caption" => @caption, "description" => title }
      end

      def title
        @caption
      end

      def titles
        @raw_titles || { urn.language => title }
      end
    end
  end
end

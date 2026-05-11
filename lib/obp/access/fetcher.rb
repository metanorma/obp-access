module Obp
  class Access
    class Fetcher
      USER_AGENT_PROFILES = [
        {
          user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36",
          platform: '"macOS"',
          chrome_version: "131",
        },
        {
          user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/130.0.0.0 Safari/537.36",
          platform: '"Windows"',
          chrome_version: "130",
        },
        {
          user_agent: "Mozilla/5.0 (X11; Linux x86_64) " \
                      "AppleWebKit/537.36 (KHTML, like Gecko) " \
                      "Chrome/131.0.0.0 Safari/537.36",
          platform: '"Linux"',
          chrome_version: "131",
        },
      ].freeze

      def initialize(urn:)
        @urn = urn
      end

      def fetch_state
        response = post_ui_request
        parse_state(response)
      end

      private

      def post_ui_request
        uri = URI(API_URL)
        request = Net::HTTP::Post.new(uri)
        profile = USER_AGENT_PROFILES.sample
        request["User-Agent"] = profile[:user_agent]
        request["Accept"] = "application/json"
        request.set_form_data(
          "v-browserDetails" => 1,
          "theme" => "iso-red",
          "v-loc" => "#{API_URL}##{@urn}",
        )

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end

      def parse_state(response)
        json = JSON.parse(response.body)
        state_json = JSON.parse(json["uidl"])
        state_json["state"].values
      end
    end
  end
end

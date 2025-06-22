module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Tig < Base
            def self.classes
              %w[sts-tbx-term]
            end

            def id
              # The ID is attached to the section, not this div
              node.parent.at_css("div.sts-tbx-label").text.strip
            end

            def index
              node.path.match(/\[(\d+)\](?=\z)/)[1].to_i - 1 # Extract index from xpath
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:tig", id: "term_#{id}-#{index}") do
                  term, part_of_speech = tbx_category(node)
                  # Force xml tags generation rather than html escaping
                  xml.send(:"tbx:term") do
                    xml << term
                  end
                  xml.send(:"tbx:partOfSpeech", value: part_of_speech)
                end
              end
            end
          end
        end
      end
    end
  end
end

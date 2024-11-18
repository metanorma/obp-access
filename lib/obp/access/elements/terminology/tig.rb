module Obp
  module Access
    class Rendered
      class Elements
        class Terminology
          class Tig < Elements::Base
            def self.classes
              %w[sts-tbx-term]
            end

            def target
              "/tbx:termEntry/tbx:langSet"
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:tig") do # NOTE: Do we need to generate an id?
                  xml.send(:"tbx:term", node.content.strip)
                  xml.send(:"tbx:partOfSpeech", value: "noun") # NOTE: Is this always noun?
                  # NOTE: How to generate tbx:normativeAuthorization ?
                end
              end
            end
          end
        end
      end
    end
  end
end

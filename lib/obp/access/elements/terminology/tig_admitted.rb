module Obp
  module Access
    class Renderer
      class Elements
        class Terminology
          class TigAdmitted < Tig
            def self.classes
              %w[sts-tbx-term admittedTerm]
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.send(:"tbx:tig", id: "term_#{id}-#{index}") do
                  term, part_of_speech = tbx_category(node)
                  xml.send(:"tbx:term") { xml << term } # Force xml tags generation rather than html escaping
                  xml.send(:"tbx:partOfSpeech", value: part_of_speech)
                  xml.send(:"tbx:normativeAuthorization", value: "admittedTerm")
                end
              end
            end
          end
        end
      end
    end
  end
end

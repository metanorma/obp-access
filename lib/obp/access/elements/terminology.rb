module Obp
  module Access
    class Renderer
      class Elements
        class Terminology < Base
          def self.classes
            %w[sts-section sts-tbx-sec]
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.send(:"term-sec", id: "sec_#{id}") do
                xml.label id
                xml.send(:"tbx:termEntry", id: "term_#{id}") do
                  xml.send(:"tbx:langSet", "xml:lang": "en")
                end
              end
            end
          end
        end
      end
    end
  end
end

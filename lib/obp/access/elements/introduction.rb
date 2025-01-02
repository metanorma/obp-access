module Obp
  class Access
    class Renderer
      class Elements
        class Introduction < Base
          def self.classes
            %w[sts-section]
          end

          def match_node?
            # Section foreword & introduction ids finishes with "foreword" & "intro"
            super && (id == "foreword" || id == "intro")
          end

          def target
            "front"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec(id: "sec_#{id}", "sec-type": id)
            end
          end
        end
      end
    end
  end
end

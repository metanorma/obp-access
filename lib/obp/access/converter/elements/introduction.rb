module Obp
  module Access
    class Converter
      class Elements
        class Introduction < Base
          def match_node?
            id == "intro"
          end

          def target
            :front
          end

          def to_xml
            Nokogiri::HTML::DocumentFragment.parse <<~EOHTML
              <sec id="introduction.int">
                <title>Introduction</title>
              </sec>
            EOHTML
          end
        end
      end
    end
  end
end

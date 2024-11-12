module Obp
  module Access
    class Converter
      class Elements
        class Section < Base
          def match_node?
            id =~ /\A\d+\Z/
          end

          def target
            :body
          end

          def to_xml
            Nokogiri::HTML::DocumentFragment.parse <<~EOHTML
              <sec id="sub-#{id}">
                <label>#{id}</label>
              </sec>
            EOHTML
          end
        end
      end
    end
  end
end

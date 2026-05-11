module Obp
  class Access
    class ElementRegistry
      class << self
        def register(element_class)
          elements << element_class
          @css_classes = nil
        end

        def elements
          @elements ||= []
        end

        def css_classes
          @css_classes ||= elements.filter_map(&:classes).uniq
        end
      end
    end
  end
end

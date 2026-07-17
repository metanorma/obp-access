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

        # Flattened unique class names across all registered elements, so
        # callers can test membership against individual node classes.
        def css_classes
          @css_classes ||= elements.filter_map(&:classes).flatten.uniq
        end
      end
    end
  end
end

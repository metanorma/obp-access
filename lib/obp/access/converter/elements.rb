module Obp
  module Access
    class Converter
      class Elements
        def self.descendants
          ObjectSpace.each_object(Class).select { |klass| klass < Base }
        end
      end
    end
  end
end

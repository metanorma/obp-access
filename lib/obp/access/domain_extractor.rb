module Obp
  class Access
    class DomainExtractor
      Result = Struct.new(:domains, :clean_children, keyword_init: true)

      DOMAIN_PATTERN = /\A\s*<([^>]+)>/
      MAX_DOMAIN_LENGTH = 50

      def self.extract(node)
        state = { domains: [], clean_children: [], text_consumed: false }

        node.children.each { |child| process_child(child, state) }

        Result.new(domains: state[:domains], clean_children: state[:clean_children])
      end

      class << self
        private

        def process_child(child, state)
          if !state[:text_consumed] && child.is_a?(Nokogiri::XML::Text)
            process_leading_text(child, state)
          else
            state[:clean_children] << child
            state[:text_consumed] = true
          end
        end

        def process_leading_text(child, state)
          extracted, remaining = extract_from_text(child.content)
          state[:domains] = extracted
          state[:text_consumed] = true
          state[:clean_children] << remaining_node(remaining) unless remaining.strip.empty?
        end

        def extract_from_text(text)
          domains = []
          remaining = text.dup

          while remaining =~ DOMAIN_PATTERN
            candidate = $1.strip
            break unless valid_domain?(candidate)

            domains << candidate
            remaining = remaining.sub(DOMAIN_PATTERN, "")
          end

          [domains, remaining]
        end

        def valid_domain?(text)
          text.length <= MAX_DOMAIN_LENGTH &&
            !text.include?("(") &&
            !text.match?(/\d{2,}/)
        end

        def remaining_node(text)
          Nokogiri::XML::Text.new(text, Nokogiri::HTML::Document.new)
        end
      end
    end
  end
end

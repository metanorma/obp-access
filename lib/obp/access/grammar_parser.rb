module Obp
  class Access
    class GrammarParser
      Result = Struct.new(:term, :pos, :genders, keyword_init: true)

      POS_MAP = {
        "adj." => "adjective",
        "Adj." => "adjective",
        "verb" => "verb",
      }.freeze

      GENDER_VALUES = %w[m f n].freeze

      BOLD_PATTERNS = [
        [->(t) { POS_MAP.key?(t) }, :handle_pos_marker],
        [->(t) { GENDER_VALUES.include?(t) }, :handle_gender_marker],
        [->(t) { t.match?(/\A[mfn],\z/) }, :handle_gender_with_comma],
        [->(t) { t.match?(/\A[mfn][,\s]+[mfn]([,\s]+[mfn])*\z/) }, :handle_multi_gender],
        [->(t) { t == "," }, :handle_comma],
        [->(t) { t == "〈" },                     :handle_enter_bracket],
        [->(t) { t == "〉" },                     :handle_exit_bracket],
        [->(t) { t.match?(/\A[mfn]\s+/) },       :handle_gender_qualifier],
        [->(t) { t.match?(/,.+[mfn]\z/) },       :handle_term_with_gender],
      ].freeze

      def self.parse(inner_html)
        state = { pos: "noun", genders: [], term_parts: [], in_bracket: false }
        segments = parse_segments(inner_html)

        segments.each do |seg|
          handler = find_handler(seg, state[:in_bracket])
          handler.call(seg[:text], state)
        end

        Result.new(term: clean_term(state[:term_parts]), pos: state[:pos], genders: state[:genders].uniq)
      end

      class << self
        private

        def find_handler(seg, in_bracket)
          if seg[:bold]
            bold_handler(seg[:text].strip, in_bracket)
          elsif in_bracket
            method(:handle_skip)
          else
            method(:handle_text)
          end
        end

        def bold_handler(text, in_bracket)
          _pattern, handler = BOLD_PATTERNS.find { |pred, _| pred.call(text) }
          return method(handler) if handler

          in_bracket ? method(:handle_skip) : method(:handle_term_text)
        end

        def handle_pos_marker(text, state)
          state[:pos] = POS_MAP[text.strip]
        end

        def handle_gender_marker(text, state)
          state[:genders] << text.strip
        end

        def handle_gender_with_comma(text, state)
          state[:genders] << text.strip[0]
        end

        def handle_multi_gender(text, state)
          text.strip.scan(/[mfn]/).each { |g| state[:genders] << g }
        end

        def handle_enter_bracket(_text, state)
          state[:in_bracket] = true
        end

        def handle_exit_bracket(_text, state)
          state[:in_bracket] = false
        end

        def handle_gender_qualifier(text, state)
          state[:genders] << text.strip[0]
        end

        def handle_term_with_gender(text, state)
          stripped = text.strip
          if stripped =~ /\A(.+),\s*([mfn])\z/
            state[:term_parts] << $1.strip
            state[:genders] << $2
          else
            state[:term_parts] << stripped
          end
        end

        def handle_comma(_text, _state); end

        def handle_term_text(text, state)
          state[:term_parts] << text
        end

        def handle_text(text, state)
          state[:term_parts] << text
        end

        def handle_skip(_text, _state); end

        def parse_segments(html)
          segments = []
          remaining = html.dup

          while remaining.length.positive?
            match = remaining.match(/\A(.*?)(<b>(.*?)<\/b>)(.*)/m)
            if match
              segments << { text: match[1], bold: false } if match[1].length.positive?
              segments << { text: match[3], bold: true }
              remaining = match[4]
            else
              segments << { text: remaining, bold: false }
              break
            end
          end

          segments
        end

        def clean_term(parts)
          combined = parts.join
          combined = combined.gsub(/,\s*\z/, "")
          combined.gsub(/\s+/, " ").strip
        end
      end
    end
  end
end

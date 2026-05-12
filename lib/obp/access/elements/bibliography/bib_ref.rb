# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class BibRef
          REF_PATTERN = /\A\[(\d+)\]\s*/
          DATED_PATTERN = /:\d{4}/

          attr_reader :index, :std_ref_text, :title_text, :std_id, :type

          def initialize(td_node, anchor_node)
            text = td_node.text
            @index = parse_index(text)
            @std_id = parse_std_id(anchor_node)
            @type = infer_type(text)
            @std_ref_text, @title_text = parse_parts(td_node)
          end

          private

          def parse_index(text)
            text[REF_PATTERN, 1].to_i
          end

          def parse_std_id(anchor)
            return nil unless anchor

            name = anchor.attr("name")
            return nil unless name
            return nil unless name.include?(":ref:")

            name.sub(/:ref:\d+\z/, "")
          end

          def infer_type(text)
            text.match?(DATED_PATTERN) ? "dated" : "undated"
          end

          def parse_parts(td_node)
            content = td_node.inner_html
            content = content.sub(REF_PATTERN, "")
            if content.include?("<i>")
              parts = content.split(/,\s*<i>/, 2)
              std_ref = parts[0].strip
              title = parts[1]&.sub(%r{</i>}, "")&.strip
              [std_ref, title]
            elsif content.include?(",")
              parts = content.split(",", 2)
              [parts[0].strip, parts[1]&.strip]
            else
              [content.strip, nil]
            end
          end
        end
      end
    end
  end
end

module Obp
  class Access
    class Renderer
      class Elements
        class Index < Base
          def self.classes
            %w[sts-section]
          end

          def match_node?
            super && index_section?
          end

          private

          def index_section?
            node_id = node.attr("id").to_s
            node_id.include?("sec_index") || index_title?
          end

          def index_title?
            title = node.at_css("h1.sts-sec-title")
            title&.text&.match?(/index|Index|verzeichnis/i)
          end

          def insertion_target
            "body"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.sec(id: "sec_index") do
                xml.title index_title_text
                xml.index do
                  render_index_divs(xml)
                end
              end
            end
          end

          def render_index_divs(xml)
            grouped_entries.each do |letter, entries|
              xml.public_send(:"index-div") do
                xml.title letter
                entries.each { |entry| render_index_entry(xml, entry) }
              end
            end
          end

          def render_index_entry(xml, entry)
            xml.public_send(:"index-entry") do
              xml.term entry[:term]
              entry[:refs].each do |ref|
                xml.xref("ref-type": "sec", rid: "sec_#{ref[:rid]}") { xml << ref[:text] }
              end
            end
          end

          def index_title_text
            node.at_css("h1.sts-sec-title")&.text || "Index"
          end

          def grouped_entries
            groups = {}
            current_letter = nil

            node.css("div.sts-p").each do |para|
              letter = letter_heading(para)
              if letter
                current_letter = letter
                groups[current_letter] ||= []
              elsif current_letter && index_entry?(para)
                groups[current_letter] << parse_entry(para)
              end
            end

            groups
          end

          def letter_heading(para)
            return nil unless para.inner_html.match?(/\A<b>[A-Z0-9À-Ü]<\/b>\z/)

            para.at_css("b")&.text
          end

          def index_entry?(para)
            !para.at_css("a.sts-xref").nil?
          end

          def parse_entry(para)
            term_node = para.at_css("a.sts-xref")
            { term: entry_term_text(term_node), refs: entry_refs(para) }
          end

          def entry_term_text(term_node)
            preceding = term_node.previous
            return "" unless preceding.is_a?(Nokogiri::XML::Text)

            preceding.text.strip.gsub(/[[:space:]]+/, " ").strip
          end

          def entry_refs(para)
            para.css("a.sts-xref").map do |xref|
              { rid: xref.attr("href").split(":").last, text: xref.text.strip }
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Index)

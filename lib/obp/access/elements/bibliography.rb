# frozen_string_literal: true

require_relative "bibliography/bib_ref"

module Obp
  class Access
    class Renderer
      class Elements
        class Bibliography < Base
          def self.classes
            %w[sts-section sts-ref-list]
          end

          private

          def insertion_target
            "back"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"ref-list", "content-type": "bibl", id: "sec_bibl") do
                node.css("tr").drop(1).each_with_index do |row, _index|
                  td = row.css("td:last-child")
                  anchor = row.at_css("td:first-child a[name]")
                  ref = BibRef.new(td, anchor)
                  xml.ref("content-type": "standard", id: "ref_#{ref.index}") do
                    xml.label "[#{ref.index}]"
                    render_std(xml, ref)
                  end
                end
              end
            end
          end

          def render_std(xml, ref)
            attrs = {}
            attrs["std-id"] = ref.std_id if ref.std_id
            attrs["type"] = ref.type if ref.type

            xml.std(**attrs) do
              xml.std_ref(ref.std_ref_text)
              xml.title ref.title_text if ref.title_text
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Bibliography)

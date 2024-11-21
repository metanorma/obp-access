module Obp
  module Access
    class Rendered
      class Elements
        class Root
          attr_reader :urn, :metas

          def initialize(urn:, metas:)
            @urn = urn
            @metas = metas
          end

          def content # rubocop:disable Metrics/AbcSize
            # Force namespace_inheritance to stop children inherit their parent’s namespace
            Nokogiri::XML::Builder.new(namespace_inheritance: false, encoding: "UTF-8") do |xml|
              xml.standard("xmlns:xlink": "http://www.w3.org/1999/xlink",
                           "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                           "xmlns:tbx": urn) do
                xml.front do
                  xml.send(:"std-meta") do
                    xml.permissions do
                      xml.send(:"copyright-statement", "All rights reserved")
                      xml.send(:"copyright-holder", holder)
                    end
                    xml.send(:"title-wrap", "xml:lang": language) do
                      xml.full title
                    end
                    xml.send(:"proj-id", ref_undated)
                    xml.send(:"content-language", language)
                    xml.send(:"std-ref", ref_dated, type: "dated")
                    xml.send(:"std-ref", ref_undated, type: "undated")
                    xml.send(:"doc-ref", ref)
                  end
                end
                xml.body
                xml.back
              end
            end
          end

          def to_document
            content.doc
          end

          private

          def holder
            metas["caption"].split.first
          end

          def title
            metas["description"]
          end

          def language
            @language ||= metas["caption"].scan(/\((.*?)\)/).first&.first
          end

          def ref
            metas["caption"]
          end

          def ref_dated
            metas["caption"].gsub(/\(.*?\)/, "")
          end

          def ref_undated
            @ref_undated ||= metas["caption"].split(":").first
          end
        end
      end
    end
  end
end

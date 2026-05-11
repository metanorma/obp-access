module Obp
  class Access
    class Renderer
      class Elements
        class Root
          TITLE_PARTS = %w[intro main compl].freeze

          attr_reader :urn, :metas

          def initialize(urn:, metas:)
            @urn = urn
            @metas = metas
          end

          def content # rubocop:disable Metrics/AbcSize
            Nokogiri::XML::Builder.new(namespace_inheritance: false,
                                       encoding: "UTF-8") do |xml|
              xml.standard("xmlns:xlink": "http://www.w3.org/1999/xlink",
                           "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                           "xmlns:tbx": "urn:iso:std:iso:30042:ed-2") do
                xml.front do
                  xml.public_send(:"std-meta") do
                    xml.permissions do
                      xml.public_send(:"copyright-statement", "All rights reserved")
                      xml.public_send(:"copyright-holder", holder)
                    end
                    render_titles(xml)
                    xml.public_send(:"proj-id", ref_undated)
                    xml.public_send(:"content-language", metas["language"])
                    xml.public_send(:"std-ref", ref_dated, type: "dated")
                    xml.public_send(:"std-ref", ref_undated, type: "undated")
                    xml.public_send(:"doc-ref", ref)
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

          def ref
            metas["caption"]
          end

          def ref_dated
            metas["caption"].gsub(/\(.*?\)/, "")
          end

          def ref_undated
            @ref_undated ||= metas["caption"].split(":").first
          end

          def render_titles(xml)
            metas["titles"].each do |language, title|
              next unless title

              xml.public_send(:"title-wrap", "xml:lang": language) do
                split = title.split("—")
                TITLE_PARTS.each_with_index do |e, i|
                  xml.public_send(e, split[i].strip) if split[i]
                end
                xml.full title
              end
            end
          end
        end
      end
    end
  end
end

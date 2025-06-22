module Obp
  class Access
    class Renderer
      class Elements
        class Root
          attr_reader :urn, :metas

          def initialize(urn:, metas:)
            @urn = urn
            @metas = metas
          end

          def content # rubocop:disable Metrics/AbcSize
            # Force namespace_inheritance to stop children inherit their parent’s namespace
            Nokogiri::XML::Builder.new(namespace_inheritance: false,
                                       encoding: "UTF-8") do |xml|
              xml.standard("xmlns:xlink": "http://www.w3.org/1999/xlink",
                           "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                           "xmlns:tbx": urn) do
                xml.front do
                  xml.send(:"std-meta") do
                    xml.permissions do
                      xml.send(:"copyright-statement", "All rights reserved")
                      xml.send(:"copyright-holder", holder)
                    end
                    render_titles(xml)
                    xml.send(:"proj-id", ref_undated)
                    xml.send(:"content-language", metas["language"])
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
              xml.send(:"title-wrap", "xml:lang": language) do
                split = title.split("—")
                elements = %w[intro main compl]
                elements.each_with_index do |e, i|
                  xml.send(e, split[i].strip) if split[i]
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

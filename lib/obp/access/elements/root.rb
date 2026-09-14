# frozen_string_literal: true

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
              xml.standard("xmlns:ali": "http://www.niso.org/schemas/ali/1.0/",
                           "xmlns:mml": "http://www.w3.org/1998/Math/MathML",
                           "xmlns:tbx": "urn:iso:std:iso:30042:ed-2",
                           "xmlns:xlink": "http://www.w3.org/1999/xlink",
                           "dtd-version": "1.0") do
                xml.front do
                  xml.public_send(:"std-meta", "std-meta-type": "international") do
                    std_meta_content(xml)
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

          def std_meta_content(xml)
            render_titles(xml)
            xml.public_send(:"proj-id", ref_undated)
            xml.public_send(:"release-version", urn.doc_type)
            render_std_ident(xml)
            xml.public_send(:"content-language", metas["language"])
            xml.public_send(:"std-ref", ref_dated, type: "dated")
            xml.public_send(:"std-ref", ref_undated, type: "undated")
            xml.public_send(:"doc-ref", ref)
            xml.public_send(:"self-uri", urn.to_s)
            render_permissions(xml)
          end

          def render_std_ident(xml)
            xml.public_send(:"std-ident") do
              xml.originator holder
              xml.public_send(:"doc-type", urn.doc_type)
              xml.public_send(:"doc-number", urn.doc_number)
              xml.edition urn.edition
              xml.version urn.version
            end
          end

          def render_permissions(xml)
            xml.permissions do
              xml.public_send(:"copyright-statement", "All rights reserved")
              xml.public_send(:"copyright-year", copyright_year) if copyright_year
              xml.public_send(:"copyright-holder", holder)
            end
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

          def holder
            caption&.split(/[[:space:]]/)&.first || urn.originator.upcase
          end

          def ref
            caption || urn.to_s
          end

          def ref_dated
            caption&.gsub(/\([^)]*\)/, "") || ref
          end

          def ref_undated
            @ref_undated ||= caption&.split(":")&.first || urn.doc_number
          end

          def copyright_year
            caption&.[](/:(\d{4})/, 1)
          end

          def caption
            metas["caption"]
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Tig < Base
            NORMATIVE_AUTHORIZATION = "preferredTerm"

            def self.classes
              %w[sts-tbx-term]
            end

            private

            def id
              node.parent.at_css("div.sts-tbx-label")&.text&.strip || ""
            end

            def index
              match = node.path.match(/\[(\d+)\](?=\z)/)
              match ? match[1].to_i - 1 : 0
            end

            def normative_authorization
              self.class::NORMATIVE_AUTHORIZATION
            end

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.public_send(:"tbx:tig", id: "term_#{id}-#{index}") do
                  render_tig_content(xml)
                end
              end
            end

            def render_tig_content(xml)
              result = GrammarParser.parse(parsed_html)
              xml.public_send(:"tbx:term") { xml << result.term }
              xml.public_send(:"tbx:partOfSpeech", value: result.pos)
              render_genders(xml, result.genders)
              xml.public_send(:"tbx:normativeAuthorization", value: normative_authorization)
            end

            def parsed_html
              node.inner_html
            end

            def render_genders(xml, genders)
              return unless genders.any?

              genders.each do |gender|
                xml.public_send(:"tbx:grammaticalGender", value: gender)
              end
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::Tig)

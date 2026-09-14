module Obp
  class Access
    class Renderer
      class Elements
        # OBP emits page footnotes as a trailing "sts-footnotes" container
        # holding one "sts-fn" div per note, each text prefixed with the
        # note number.
        class Footnotes < Base
          def self.classes
            %w[sts-footnotes]
          end

          private

          def insertion_target
            "back"
          end

          def content
            Nokogiri::XML::Builder.new do |xml|
              xml.public_send(:"fn-group") do
                node.css("div.sts-fn").each { |note| render_fn(xml, note) }
              end
            end
          end

          def render_fn(xml, note)
            id = fn_id(note)
            xml.fn(id: "fn_#{id}") do
              xml.label id
              xml.p fn_text(note)
            end
          end

          def fn_id(note)
            note.attr("id")&.split("_")&.last || note.object_id.to_s
          end

          def fn_text(note)
            div = note.at_css("div")
            if div
              div.text.strip.sub(/\A\d+\s*/,
                                 "")
            else
              note.text.strip.sub(/\A\d+\s*/, "")
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Footnotes)

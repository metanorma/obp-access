module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Source < Base
            def self.classes
              %w[sts-tbx-source]
            end

            private

            def content
              Nokogiri::XML::Builder.new do |xml|
                xml.public_send(:"tbx:source") do
                  node.children.each do |child|
                    if child.classes == ["sts-xref"]
                      render_ref(xml, child)
                    else
                      render_text(xml, child)
                    end
                  end
                end
              end
            end

            def render_ref(xml, child)
              rid = child.attr("href").split(":").last
              xml.xref("ref-type": "bibr", rid: "ref_#{rid}") do
                xml << child.inner_html
              end
            end

            def render_text(xml, child)
              content = child.to_s.strip.gsub(/^\[SOURCE:|\]$/, "")
              xml << content
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::Source)

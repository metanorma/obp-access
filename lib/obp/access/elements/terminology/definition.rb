module Obp
  class Access
    class Renderer
      class Elements
        class Terminology
          class Definition < Base
            def self.classes
              %w[sts-tbx-def]
            end

            private

            def insert_method
              :prepend_child
            end

            def content
              extracted = DomainExtractor.extract(node)
              @fragment = Nokogiri::XML::DocumentFragment.new(document)

              Nokogiri::XML::Builder.with(@fragment) do |xml|
                extracted.domains.each do |domain|
                  xml.public_send(:"tbx:subjectField") { xml << domain }
                end
                xml.public_send(:"tbx:definition") do
                  extracted.clean_children.each { |child| render_inline(xml, child) }
                end
              end

              @fragment
            end

            def to_xml
              content
              @fragment.to_xml
            end
          end
        end
      end
    end
  end
end

Obp::Access::ElementRegistry.register(Obp::Access::Renderer::Elements::Terminology::Definition)

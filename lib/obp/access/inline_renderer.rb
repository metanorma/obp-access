module Obp
  class Access
    module InlineRenderer
      CLASS_TYPES = {
        %w[sts-tbx-entailedTerm] => :entailed_term,
        %w[sts-xref] => :xref,
        %w[sts-std-ref] => :std_ref,
        %w[sts-label] => :label,
      }.freeze

      def render_inline(xml, node)
        return xml.text(node.content) if node.is_a?(Nokogiri::XML::Text)

        render_node_by_type(xml, node, inline_type(node))
      end

      CONTAINER_TYPES = { italic: :italic, bold: :bold }.freeze

      def render_node_by_type(xml, node, type)
        if CONTAINER_TYPES.key?(type)
          render_container(xml, node, CONTAINER_TYPES[type])
        elsif type == :label
          nil
        elsif type == :element
          render_children(xml, node)
        else
          render_named_type(xml, node, type)
        end
      end

      def render_named_type(xml, node, type)
        case type
        when :entailed_term then render_entailed_term(xml, node)
        when :xref then render_xref(xml, node)
        when :std_ref then render_std_ref(xml, node)
        when :ext_link then render_ext_link(xml, node)
        end
      end

      def render_container(xml, node, tag)
        xml.public_send(tag) { node.children.each { |c| render_inline(xml, c) } }
      end

      def render_children(xml, node)
        node.children.each { |c| render_inline(xml, c) }
      end

      def inline_type(node)
        return :text if node.is_a?(Nokogiri::XML::Text)

        CLASS_TYPES.fetch(node.classes) do
          case node.name
          when "i" then :italic
          when "a" then :ext_link
          when "b" then :bold
          else :element
          end
        end
      end

      def xref_ref_type(text)
        case text
        when /\AFigure/ then "fig"
        when /\ATable/  then "table"
        when /\ANote/   then "fn"
        else "sec"
        end
      end

      private

      def render_entailed_term(xml, node)
        target = node.at_css("a").attr("href").split(":").last
        xml.public_send(:"tbx:entailedTerm", target: "term_#{target}") do
          xml << node.text.strip
        end
      end

      def render_xref(xml, node)
        rid = node.attr("href").split(":").last
        ref_type = xref_ref_type(node.text)
        xml.xref("ref-type": ref_type, rid: "#{ref_type}_#{rid}") { xml << node.text.strip }
      end

      def render_std_ref(xml, node)
        rid = node.attr("href").split(":").last
        xml.xref("ref-type": "bibr", rid: "ref_#{rid}") { xml << node.text.strip }
      end

      def render_ext_link(xml, node)
        xml.public_send(:"ext-link", "xlink:href" => node.attr("href")) { xml << node.text.strip }
      end
    end
  end
end

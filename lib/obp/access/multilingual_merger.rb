module Obp
  class Access
    class MultilingualMerger
      include InlineRenderer

      CHILD_TYPE_RENDERERS = {
        %w[sts-tbx-def] => :render_definition,
        %w[sts-tbx-note] => :render_note,
        %w[sts-tbx-example] => :render_example,
        %w[sts-tbx-source] => :render_source,
      }.freeze

      def initialize(primary_document, additional_sources, _metas)
        @document = primary_document
        @additional_sources = additional_sources
      end

      def merge
        @additional_sources.each do |language, html|
          merge_language(language, html)
        end
        @document
      end

      private

      def merge_language(language, html)
        doc = Nokogiri::HTML(html.gsub(/[[:space:]]/, " "))
        standard = doc.at_css("div.sts-standard")
        return unless standard

        term_sections(standard).each do |section|
          label = section_label(section)
          next unless label

          term_entry = find_term_entry(label)
          next unless term_entry

          langset = build_langset(section, language)
          term_entry.add_child(langset)
        end
      end

      def find_term_entry(label)
        @document.at_xpath("//*[@id='term_#{label}' and local-name()='termEntry']")
      end

      def term_sections(standard)
        standard.css("div.sts-section.sts-tbx-sec")
      end

      def section_label(section)
        section.at_css("div.sts-tbx-label")&.text&.strip
      end

      def build_langset(section, language)
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.public_send(:"tbx:langSet", "xml:lang": language) do
            section.children.each do |child|
              render_section_child(xml, child)
            end
          end
        end
        builder.doc.root
      end

      def render_section_child(xml, child)
        return unless child.is_a?(Nokogiri::XML::Element)

        classes = child.classes
        if classes.include?("sts-tbx-term")
          render_term_type(xml, child, classes)
        else
          render_typed_child(xml, child, classes)
        end
      end

      def render_typed_child(xml, child, classes)
        renderer = CHILD_TYPE_RENDERERS[classes]
        return unless renderer

        case renderer
        when :render_definition then render_definition(xml, child)
        when :render_note then render_note(xml, child)
        when :render_example then render_example(xml, child)
        when :render_source then render_source(xml, child)
        end
      end

      def render_term_type(xml, child, classes)
        if classes.include?("deprecatedTerm")
          render_deprecated_tig(xml, child)
        else
          render_tig(xml, child)
        end
      end

      def render_tig(xml, node)
        is_bold = node.inner_html.start_with?("<b>")
        norm_auth = is_bold ? "admittedTerm" : "preferredTerm"
        result = GrammarParser.parse(node.inner_html)

        xml.public_send(:"tbx:tig") do
          xml.public_send(:"tbx:term") { xml << result.term }
          xml.public_send(:"tbx:partOfSpeech", value: result.pos)
          result.genders.each { |g| xml.public_send(:"tbx:gram", value: g, type: "gender") }
          xml.public_send(:"tbx:normativeAuthorization", value: norm_auth)
        end
      end

      def render_deprecated_tig(xml, node)
        clean_html = node.inner_html.gsub(%r{<span class="sts-tbx-term-depr-label">.*?</span>}, "")
        result = GrammarParser.parse(clean_html)

        xml.public_send(:"tbx:tig") do
          xml.public_send(:"tbx:term") { xml << result.term }
          xml.public_send(:"tbx:partOfSpeech", value: result.pos)
          result.genders.each { |g| xml.public_send(:"tbx:gram", value: g, type: "gender") }
          xml.public_send(:"tbx:normativeAuthorization", value: "deprecatedTerm")
        end
      end

      def render_definition(xml, node)
        extracted = DomainExtractor.extract(node)

        extracted.domains.each do |domain|
          xml.public_send(:"tbx:subjectField") { xml << domain }
        end

        xml.public_send(:"tbx:definition") do
          extracted.clean_children.each { |child| render_inline(xml, child) }
        end
      end

      def render_note(xml, node)
        label = node.at_css("span.sts-tbx-note-label")
        content_node = node.at_css("div.sts-tbx-note-content") || node

        xml.public_send(:"tbx:note") do
          xml.label label.text if label
          content_node.children.each { |child| render_inline(xml, child) }
        end
      end

      def render_example(xml, node)
        label = node.at_css("span.sts-tbx-example-label")

        xml.public_send(:"tbx:example") do
          xml.label label.text if label
          node.children.each do |child|
            next if child.classes&.include?("sts-tbx-example-label")

            render_inline(xml, child)
          end
        end
      end

      def render_source(xml, node)
        xml.public_send(:"tbx:source") do
          node.children.each { |child| render_inline(xml, child) }
        end
      end
    end
  end
end

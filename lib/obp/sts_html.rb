#!/usr/bin/env ruby

# require "pry"
require "sts"
require "pubid-iso"
require "nokogiri"
require "shale"
require "shale/adapter/nokogiri"
Shale.xml_adapter = Shale::Adapter::Nokogiri

module Obp
  class StsHtml
    attr_accessor :filename, :doc, :cleaned

    def initialize(filename)
      @filename = filename
      metadata_path = Pathname.new(filename).dirname.join("metadata.yml")
      metadata(metadata_path)
      load
      clean
    end

    def load
      @doc = Nokogiri::HTML(open(@filename))
    end

    def clean
      return @cleaned if @cleaned

      @cleaned = Nokogiri::XML(@doc.css(".sts-standard").to_xml)
      @cleaned.css("[xmlns]").remove_attr("xmlns")
      @cleaned.css("div.commentable").remove
      @cleaned.css("div[style]").remove

      @cleaned.css("div.list").each do |ele|
        # ele.remove_class('list')
        # ele.name = 'list'
        ele.replace(ele.children)
      end

      @cleaned.css("ul").each do |ele|
        ele.name = "list"
        ele.remove_attribute("list-style-type")
        ele["list-type"] = "bullet"
      end

      @cleaned.css("ol").each do |ele|
        ele.name = "list"
        ele.remove_attribute("list-style-type")
        ele["list-type"] = "alpha-lower"
      end

      @cleaned.css("li").each do |ele|
        ele.name = "list-item"
      end

      @cleaned.css("[id]").each do |ele|
        ele["id"] = urn_to_prefix(ele["id"])
      end

      @cleaned.css('[class^="sts-"]').each do |ele|
        class_first = ele.attribute("class").value.strip
        if class_first.include?(" ")
          class_first, class_second = class_first.split(" ").first
          if class_second == "sts-tbx-sec"
            class_first = "sts-tbx-sec"
          end
        end

        class_name = case class_first
                     when "sts-section"
                       "sec"
                     when "sts-sec-title"
                       "title"
                     when "sts-caption"
                       "caption"
                     when "sts-caption-label"
                       "label"
                     when "sts-caption-title"
                       "title"
                     when "sts-copyright"
                       "copyright-statement"
                     when "sts-fig"
                       "fig"
                     when "sts-label"
                       "label"
                     when "sts-non-normative-note"
                       "non-normative-note"
                     when "sts-non-normative-note-label"
                       "label"
                     when "sts-p"
                       "p"
                     when "sts-ref-list"
                       "ref-list"
                     when "sts-standard"
                       "standard"
                     when "sts-table-wrap"
                       "table-wrap"
                     when "sts-tbx-def"
                       "tbx--definition"
                     when "sts-tbx-entailedTerm"
                       "tbx--entailedTerm"
                     when "sts-tbx-entailedTerm-num"
                       "num"
                     when "sts-tbx-example"
                       "tbx--example"
                     when "sts-tbx-example-content"
                       "p"
                     when "sts-tbx-example-label"
                       "label"
                     when "sts-tbx-label"
                       "label"
                     when "sts-tbx-note"
                       "tbx--note"
                     when "sts-tbx-note-label"
                       "label"
                     when "sts-tbx-sec"
                       "term-sec"
                     when "sts-tbx-source"
                       "tbx--source"
                     when "sts-tbx-term"
                       "tbx--term"
                     when "sts-tbx-term-depr-label"
                       "label"
                     when "sts-xref"
                       "xref"
                     else
                       raise StandardError.new("class_first #{class_first} not recognized")
                     end

        ele.remove_class(class_first)
        ele.name = class_name
      end

      # Move list item <label> up one level to under <list-item>
      @cleaned.css("list-item > p > label").each do |ele|
        ele.parent.children.delete(ele)
        ele.parent.parent.prepend_child(ele)
      end

      # Extract sec <label> from <title> and add it under <sec>
      @cleaned.css("sec > title").each do |ele|
        # Strip titles
        ele.content = ele.text.strip
        match = ele.content.match(/^([\d\.]+)[\s ]+(.*)$/)
        next unless match

        label_ele = Nokogiri::XML::Node.new("label", @cleaned).tap do |label|
          label.content = match[1]
        end

        ele.content = match[2]
        ele.parent.prepend_child(label_ele)
      end

      # @cleaned.css('sts-copyright').each do |ele|
      #   ele.replace(ele.children)
      # end

      # @cleaned.css("standard").first.add_namespace("tbx", "urn:iso:std:iso:30042:ed-1")

      @cleaned
    end

    def metadata(metadata_path)
      @metadata = YAML.load_file(
        metadata_path,
        permitted_classes: [Time],
      )
    end

    def identifier
      @identifier ||= Pubid::Iso::Identifier.parse(@metadata["identifier"].strip)
      # @identifier_urn = Pubid::Iso::Identifier.parse(@metadata["urn"].strip)
    end

    def title
      return @title if @title

      title_concat = @metadata["title"].strip
      @title = {
        intro: nil,
        main: nil,
        part: nil,
        full: title_concat,
      }

      # Check if there is a "Part X:" text, and then parse from there.
      if title_concat.index(/Part \d+:/)
        # has title
        # title_split = @metadata[:title].strip.split('—')
        raise "Building a Part document not implemented."
      else
        title_split = title_concat.split("—").map(&:strip)

        case title_split.length
        when 1
          @title[:main] = title_split[0]
        when 2
          @title[:intro] = title_split[0]
          @title[:main] = title_split[1]
        when 3
          @title[:intro] = title_split[0..1]
          @title[:main] = title_split[2]
        when 4
          @title[:intro] = title_split[0..2]
          @title[:main] = title_split[3]
        end
      end

      @title
    end

    def urn_to_prefix(html_id)
      html_id
        .gsub("toc_#{@metadata['urn'].gsub(':', '_')}_", "")
        .gsub("#{@metadata['urn'].gsub(':', '_')}_", "")
    end

    def section_by_id(id)
      @cleaned.css("##{id}")
    end

    def edition
      @metadata["urn"].match(/:ed-(\d+):/)[1]
    end

    def foreword
      sec_foreword = section_by_id("sec_foreword")

      paragraphs = sec_foreword.css("> p")
      Sts::NisoSts::Section.new.tap do |sec|
        sec.type = "foreword"
        sec.id = "sec_foreword"
        sec.title = Sts::NisoSts::Title.new.tap do |title|
          title.content = sec_foreword.css("title").text
        end
        sec.paragraphs = paragraphs.map do |p|
          xml_to_sts_class(p) if p.name == "p"
        end
      end
    end

    # TODO: can contain subclauses numbered `0.\d`
    def introduction
      sec_intro = section_by_id("sec_intro")

      Sts::NisoSts::Section.new.tap do |sec|
        sec.type = "intro"
        sec.id = "sec_intro"
        sec.title = Sts::NisoSts::Title.new.tap do |title|
          title.content = sec_intro.css("title").text
        end
        sec.specific_use = "introduction.int"
        sec.paragraphs = sec_intro.children.map do |p|
          xml_to_sts_class(p) if p.name == "p"
        end
      end
    end

    def bibliography
      sec_bibl = section_by_id("sec_bibl")

      Sts::NisoSts::App.new.tap do |sec|
        sec.id = "sec_bibl"
        sec.annex_type = "(informative)"
        sec.content_type = "bibl"
        sec.title = xml_to_sts_class(sec_bibl.css("> title:first").first)
        sec.ref_list = xml_to_sts_class(sec_bibl.css("> ref-list:first"))
      end
    end

    def copyright_statement_text
      @cleaned.css("copyright-statement > div:first").text.strip
    end

    def xml_to_sts_class(xml)
      return unless xml

      if xml.is_a?(Nokogiri::XML::NodeSet)
        return xml.map do |ele|
                 xml_to_sts_class(ele)
               end
      end

      case xml.name
      when "text"
        xml.text
      when "p"
        children = xml.children.map do |child|
          xml_to_sts_class(child)
        end

        Sts::NisoSts::Paragraph.new.tap do |p|
          # TODO: Need to set content properly, Sts::NisoSts::Paragraph takes
          # mixed tagged content
          p.text = children.join("")
        end
      when "sec"
        label = xml.css("> label:first")
        title = xml.css("> title:first")
        Sts::NisoSts::Section.new.tap do |sec|
          sec.type = "clause"
          unless label.empty?
            label = label.first if label.is_a?(Nokogiri::XML::NodeSet)
            sec.label = xml_to_sts_class(label)
          end

          unless title.empty?
            sec.title = Sts::NisoSts::Title.new.tap do |section_title|
              section_title.content = xml_to_sts_class(title)
            end
          end
          sec.paragraphs = xml.children.map do |p|
            xml_to_sts_class(p) if p.name == "p"
          end.compact
        end
      when "list"
        children = xml.children.map do |child|
          xml_to_sts_class(child)
        end

        Sts::NisoSts::List.new.tap do |list|
          list.list_type = xml.attributes["list-type"].value
          list.list_item = children.select do |c|
            c.is_a?(Sts::NisoSts::ListItem)
          end
        end
      when "list-item"
        paragraphs = xml.css("> p")
        label = xml.css("> label:first")
        Sts::NisoSts::ListItem.new.tap do |list_item|
          list_item.label = xml_to_sts_class(label) unless label.empty?
          list_item.p = paragraphs.map do |p|
            xml_to_sts_class(p)
          end
        end
      when "label"
        Sts::NisoSts::Label.new.tap do |label|
          label.content = xml.text.strip
        end
      when "title"
        Sts::NisoSts::Title.new.tap do |title|
          title.content = xml.text.strip
        end
      when "ref-list"
        table_rows = xml.css("> tbody > tr")

        Sts::NisoSts::ReferenceList.new.tap do |ref_list|
          ref_list.ref = table_rows.map do |tr|
            urn = tr.css("> label > a:first").first.attributes["name"].value
            number = urn.match(/ref:(\d+)/)[1]
            presented = tr.css("> td:first").first

            case presented.text
            when /^(\[\d+\])[\t\s]+([^,]+),\s+(.*)$/
              # has ref label, pubid and title
              match = presented.text.match(/^(\[\d+\])[\t\s]+([^,]+),\s+(.*)$/)
              ref_id = match[2]
              ref_title = match[3]
            when /^(\[\d+\])?[\t\s]+(.*)$/
              # has ref label, title
              match = presented.text.match(/^(\[\d+\])?[\t\s]+(.*)$/)
              ref_id = nil
              ref_title = match[2].strip
            when /^(.*)$/
              # Only has title
              match = presented.text.match(/^(.*)$/)
              ref_id = nil
              ref_title = match[1]
            end

            Sts::NisoSts::Reference.new.tap do |ref|
              ref.label = Sts::NisoSts::Label.new.tap do |label|
                label.content = number
              end

              # TODO: Deal with citations that are not standards
              ref.std = [Sts::NisoSts::ReferenceStandard.new.tap do |std|
                std.type = "standard"
                std.title = ref_title
                if ref_id
                  std.std_ref = Sts::NisoSts::StandardRef.new(value: ref_id)
                end
              end]
            end
          end
        end
      end
    end

    def to_sts
      @document = Sts::NisoSts::Standard.new.tap do |doc|
        doc.lang = identifier.language

        doc.front = Sts::NisoSts::Front.new.tap do |front|
          front.iso_meta = Sts::NisoSts::MetadataIso.new.tap do |iso_meta|
            iso_meta.content_language = identifier.language

            iso_meta.title_wrap = Sts::NisoSts::TitleWrap.new.tap do |title_wrap|
              title_wrap.full = Sts::NisoSts::TitleFull.new.tap do |title_full|
                title_full.content = title[:full]
              end
              title_wrap.main = title[:main]
              title_wrap.intro = title[:intro]
              title_wrap.lang = identifier.language
            end

            iso_meta.std_ident = Sts::NisoSts::StandardIdentification.new.tap do |std_ident|
              std_ident.doc_number = identifier.number
              std_ident.originator = identifier.publisher
              std_ident.doc_type = identifier.type[:key].to_s
              std_ident.edition = edition
            end

            iso_meta.permissions = Sts::NisoSts::Permissions.new.tap do |permissions|
              permissions.copyright_statement = copyright_statement_text
              permissions.copyright_year = identifier.year
              permissions.copyright_holder = identifier.publisher
            end

            iso_meta.doc_ref = identifier.to_s(format: :ref_undated)
            iso_meta.std_ref = [
              Sts::NisoSts::StandardRef.new.tap do |std_ref|
                std_ref.type = "undated"
                std_ref.value = identifier.to_s(format: :ref_undated)
              end,
              Sts::NisoSts::StandardRef.new.tap do |std_ref|
                std_ref.type = "dated"
                std_ref.value = identifier.to_s(format: :ref_dated)
              end,
            ]
          end

          front.sec << foreword
          front.sec << introduction
        end

        # TODO: insert Scope (Clause 1) till the end before Annex (haven't
        # checked how Annexes are represented in HTML)
        doc.body = Sts::NisoSts::Body.new.tap do |body|
          sections = @cleaned.css('standard > sec[id^="sec_"]').select do |x|
            x.attr("id") =~ /sec_\d+/
          end

          body.sec = sections.map do |sec|
            xml_to_sts_class(sec)
          end
        end

        # TODO
        doc.back = Sts::NisoSts::Back.new.tap do |back|
          back.app_group = Sts::NisoSts::AppGroup.new.tap do |app_group|
            # TODO: for every Annex, insert <app> under <app-group><app.../>
            # app_group.app << Sts::NisoSts::App.new(content_type: "norm-annex", body: "xxx")
            # app_group.app << Sts::NisoSts::App.new(content_type: "inform-annex", body: "xxx")

            app_group.app << bibliography
          end
          # TODO: insert <sec id="sec_index"> for index if any
          # body.sec << Sts::NisoSts::Sec.new(id: "sec_index", specific_use: "index", body: "xxx")
          # insert <fn-group> for footnotes if any
        end
      end

      @document
    end
  end
end

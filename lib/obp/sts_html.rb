#!/usr/bin/env ruby

require 'nokogiri'
require 'shale'
require 'shale/adapter/nokogiri'
Shale.xml_adapter = Shale::Adapter::Nokogiri

module Obp
  class StsHtml
    attr_accessor :filename, :doc, :cleaned

    def initialize(filename)
      @filename = filename
      load
    end

    def load
      @doc = Nokogiri::HTML(open(@filename))
      @cleaned = false
    end

    def clean
      @xml = Nokogiri::XML(@doc.css(".sts-standard").to_xml)

      @xml.css('[xmlns]').remove_attr('xmlns')

      @xml.css('div.commentable').remove
      @xml.css('div[style]').remove

      @xml.css('div.list').each do |ele|
        # ele.remove_class('list')
        # ele.name = 'list'
        ele.replace(ele.children)
      end

      @xml.css('ul').each do |ele|
        ele.name = 'list'
        ele.remove_attribute('list-style-type')
        ele['list-type'] = 'bullet'
      end

      @xml.css('ol').each do |ele|
        ele.name = 'list'
        ele.remove_attribute('list-style-type')
        ele['list-type'] = 'alpha-lower'
      end

      @xml.css('li').each do |ele|
        ele.name = 'list-item'
      end

      @xml.css('[class^="sts-"]').each do |ele|
        class_first = ele.attribute('class').value.strip
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
        when "sts-sec-title"
          "title"
        when "sts-standard"
          "standard"
        when "sts-table-wrap"
          "table-wrap"
        when "sts-tbx-def"
          'tbx:definition'
        when "sts-tbx-entailedTerm"
          'tbx:entailedTerm'
        when "sts-tbx-entailedTerm-num"
          'num'
        when "sts-tbx-example"
          'tbx:example'
        when "sts-tbx-example-content"
          'p'
        when "sts-tbx-example-label"
          "label"
        when "sts-tbx-label"
          "label"
        when "sts-tbx-note"
          "tbx:note"
        when "sts-tbx-note-label"
          "label"
        when "sts-tbx-sec"
          "term-sec"
        when "sts-tbx-source"
          "tbx:source"
        when "sts-tbx-term"
          "tbx:term"
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

      # @xml.css('sts-copyright').each do |ele|
      #   ele.replace(ele.children)
      # end

      @xml.css('standard').first.add_namespace('tbx', "urn:iso:std:iso:30042:ed-1")

      @cleaned = true

      self
    end

    def to_xml
      unless @cleaned
        raise StandardError.new("Document not cleaned!")
      end

      @xml.to_xml(pretty: true)
    end
  end

  class StsP < Shale::Mapper
    attribute :text, Shale::Type::String

    xml do
      root 'p'
      map_content to: :text
    end
  end

  class StsList < Shale::Mapper
    attribute :text, Shale::Type::String

    xml do
      root 'list'
      map_content to: :text
    end
  end

  class StsSection < Shale::Mapper
    attribute :sec, StsSection
    attribute :id, Shale::Type::String
    attribute :title, Shale::Type::String
    attribute :p, StsP, collection: true
    attribute :list, StsList, collection: true

    xml do
      root 'standard'
      map_element 'sec', to: :sec
      map_element 'h1', to: :title
      map_attribute 'id', to: :id
      map_element 'p', to: :p
      map_element 'list', to: :list
    end
  end

  class StsStandard < Shale::Mapper
    attribute :sec, StsSection, collection: true
    attribute :copyright, Shale::Type::String

    xml do
      root 'standard'
      map_element 'sec', to: :sec
      map_element 'copyright-statement', to: :copyright
    end

  end
end

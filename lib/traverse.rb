require "traverse/version"
require 'nokogiri'
require 'active_support/inflector'

module Traverse
  class Document
    def initialize document
      setup_underlying_document document

      if text_node?
        define_singleton_method "text" do
          @document.children.first.content
        end
      end

      singular_children.group_by(&:name).each do |name, children|
        if children.count == 1
          child = children.first
          if text_only_node? child
            define_singleton_method name do
              child.content.strip
            end
          else
            define_singleton_method name do 
              Document.new child
            end
          end
        else
          define_singleton_method name.pluralize do
            children.map do |child|
              if text_only_node? child
                child.content.strip
              else
                Document.new child
              end
            end
          end
        end
      end

      plural_children.each do |pluralized_child|
        define_singleton_method pluralized_child.name do
          pluralized_child.children.reject do |baby|
            baby.class == Nokogiri::XML::Text
          end.map { |child| Document.new child }
        end
      end

    end

    def [] attr
      @document.get_attribute attr
    end

    def attributes
      name_value_pairs = @document.attributes.map do |name, attribute|
        [name, attribute.value]
      end
      Hash[ name_value_pairs ]
    end

    def children
      real_children.map { |child| Document.new child }
    end

    private
      def method_missing m, *args, &block
        self[m] or super
      end

      def text_node?
        @document.children.all? do |child|
          child.is_a? Nokogiri::XML::Text
        end
      end

      def text_only_node? node
        node.children.all? do |child|
          child.is_a? Nokogiri::XML::Text
        end and node.attributes.empty?
      end

      def real_children
        @document.children.reject do |child|
          child.is_a? Nokogiri::XML::Text
        end
      end

      def singular_children
        real_children.select do |child|
          child.children.any? do |baby|
            if baby.class == Nokogiri::XML::Text
              false # ignore text children
            else
              baby.name != child.name.singularize
            end
          end or child.children.all? do |baby|
            baby.class == Nokogiri::XML::Text
          end
        end
      end

      def plural_children
        real_children.select do |child|
          child.children.all? do |baby|
            if baby.class == Nokogiri::XML::Text
              true # ignore text children
            else
              baby.name == child.name.singularize
            end
          end and child.children.count > 1
        end
      end

      def find_first_non_comment_node xml_string
        Nokogiri::XML(xml_string).children.find do |child|
          !child.comment?
        end
      end

      def setup_underlying_document document
        if document.is_a? String
          begin
            @document = find_first_non_comment_node document
          rescue
            nil
          end
        elsif document.respond_to? :read # is it file-like...
          begin
            @document = find_first_non_comment_node document.read
          rescue
            nil
          end
        elsif document.is_a? Nokogiri::XML::Document
          @document = document.children.find do |child|
            !child.comment?
          end
        else
          @document = document
        end
      end

      def to_s
        "<Traversable... >"
      end
  end
end

require "traverse/version"
require 'nokogiri'
require 'open-uri'
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
      if @document.is_a? Nokogiri::XML::Document
        {}
      else
        name_value_pairs = @document.attributes.map do |name, attribute|
          [name, attribute.value]
        end
        Hash[ name_value_pairs ]
      end
    end

    def children
      real_children.map { |child| Document.new child }
    end

    private
      def method_missing m, *args, &block
        self[m] or super
      end

      def text_node?
        num_children = @document.children.count
        return false unless num_children == 1

        @document.children.first.is_a? Nokogiri::XML::Text
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
              true
            else
              baby.name == child.name.singularize
            end
          end and child.children.count > 1
        end
      end

      def setup_underlying_document document
        if document.is_a? String
          begin
            @document = Nokogiri::XML(document)
          rescue
            return nil
          end
        else
          @document = document
        end
      end

      def to_s
        "<Traversable... >"
      end
  end

  module Proxy
    private
      def proxy *args
        if args.empty?
          @proxy
        else
          @proxy = args.first
          def method_missing m
            @proxy.send m
          end
        end
      end
  end
end

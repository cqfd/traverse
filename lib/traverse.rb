require "traverse/version"
require 'nokogiri'
require 'yajl'
require 'active_support/inflector'
require 'yajl'

module Traverse
  class Document
    def initialize document
      if xml? document
        @proxy = XML.new document
      elsif json? document
        @proxy = JSON.new document
      end
    end

    private
      def method_missing m, *args, &block
        @proxy.send m, *args, &block
      end

      def xml? document
        begin
          Nokogiri::XML(document) do |config|
            config.options = Nokogiri::XML::ParseOptions::STRICT
          end
          true
        rescue Nokogiri::XML::SyntaxError
          false
        ensure
          document.rewind if document.respond_to? :read
        end
      end

      def json? document
        begin
          Yajl::Parser.new.parse(document)
          true
        rescue Yajl::ParseError
          false
        ensure
          document.rewind if document.respond_to? :read
        end
      end

      def to_s
        "<Traverse::Document...>"
      end
  end

  class XML
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
              XML.new child
            end
          end
        else
          define_singleton_method name.pluralize do
            children.map do |child|
              if text_only_node? child
                child.content.strip
              else
                XML.new child
              end
            end
          end
        end
      end

      plural_children.each do |pluralized_child|
        define_singleton_method pluralized_child.name do
          pluralized_child.children.reject do |baby|
            baby.class == Nokogiri::XML::Text
          end.map { |child| XML.new child }
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
      real_children.map { |child| XML.new child }
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

  class JSON

    def initialize json

      setup_underlying_json json

      if @json.is_a? Array
        @proxy = @json.map do |item|
          JSON.new item
        end
      elsif @json.is_a? Hash
        @json.each_pair do |k,v|
          define_singleton_method k do
            if v.is_a? Hash
              JSON.new(v)
            elsif v.is_a? Array
              v.map { |i| JSON.new(i) }
            else
              v
            end
          end
          define_singleton_method "_keys_" do
            @json.keys
          end
        end
      elsif @json.is_a? Array
        @json.map! { |i| JSON.new i }
      end
      # _length_
      define_singleton_method "_length_" do
        @json.length
      end
    end

    private
      # Overload method_missing, pass method to super
      def method_missing m, *args, &block
        if @proxy
          @proxy.send m, *args, &block
        else
          super
        end
      end
      
      def setup_underlying_json document
        if document.is_a? String
          @json = Yajl::Parser.new.parse document
        elsif document.respond_to? :read # Tempfile / StringIO
          begin
            parser = Yajl::Parser.new
            @json = parser.parse(document)
          rescue
            nil
          ensure
            document.rewind
          end
        elsif document.is_a? Hash
          @json = document
        end
      end
  end
end

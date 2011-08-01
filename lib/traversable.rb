require "traversable/version"
require 'nokogiri'
require 'open-uri'

module Traversable
  class Document
    def initialize document
      if document.is_a? String
        begin
          @document = Nokogiri::XML(document)
        rescue
          return nil
        end
      else
        @document = document
      end

      if text_node?
        define_singleton_method "text" do
          @document.children.first.content
        end
      else
        @document.children.reject do |child|
          child.is_a? Nokogiri::XML::Text
        end.group_by(&:name).each do |name, children|
          if children.count == 1
            define_singleton_method "#{name}" do 
              Document.new children.first
            end
          else
            define_singleton_method "#{name}s" do
              children.map { |child| Document.new child }
            end
          end
        end
      end
    end

    def [] attr
      @document.get_attribute attr
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

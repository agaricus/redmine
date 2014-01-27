require 'easy_xml_helper/xml/xml_node_base'

module EasyXmlHelper
  module Xml

    class XmlNodeCollectionBase < EasyXmlHelper::Xml::XmlNodeBase
      include Enumerable
      extend Forwardable

      def_delegators :@items, :each, :[], :size

      class << self
        attr_reader :collection_types
      end

      attr_reader :items
      protected :items

      def initialize(parent_xml_node, xpath, namespaces)
        current_xml_node = self.class.get_xml_node_set(parent_xml_node, xpath, namespaces).first
        
        super(current_xml_node)

        ensure_items
      end

      # Defines self as a xml collection of single type
      # Usages:
      # => xml_collection_type EasyDataTemplates::MsProject2010::Resource, 'xmlns:Resource'
      def self.xml_collection_type(klass, xpath)
        @collection_types ||= {}
        @collection_types[xpath] = klass
      end

      protected

      def ensure_items
        return false if self.class.collection_types.blank?

        @items = []

        self.class.collection_types.each do |xpath, klass|          
          self.class.get_xml_node_set(@current_xml_node, xpath, @current_xml_node.namespaces).each do |item_xml_node|
            @items << klass.new(item_xml_node)            
          end
        end
        return true
      end

    end
    
  end
end
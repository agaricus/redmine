require 'easy_xml_helper/xml/xml_node_collection_base'

module ModificationFg
  module Xml

    class XmlGenericCollection < EasyXmlHelper::Xml::XmlNodeCollectionBase

      def initialize(parent_xml_node, klass, xpath)
        self.class.xml_collection_type klass, xpath
        super(parent_xml_node, '.', parent_xml_node.namespaces)
      end

    end

  end
end
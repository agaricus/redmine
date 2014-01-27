module EasyXmlHelper
  module Xml

    class XmlParser

      attr_reader :xml_doc, :root_element
  
      def initialize(file_path)
        load_xml(file_path)

        assign_root_element
        
        raise ArgumentError, 'Cannot find a root element inside a XML file.' if @root_element.nil?
      end

      def assign_root_element
        raise NotImplementedError, 'You have to override this method.'
      end
  
      protected

      def load_xml(file_path)
        raise ArgumentError, "File '#{file_path}' not found!" unless File.exists?(file_path)

        @xml_doc = Nokogiri::XML(open(file_path))
      end

    end
  end
end

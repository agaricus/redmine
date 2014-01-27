module EasyXmlHelper
  module Xml

    class XmlNodeBase

      attr_reader :current_xml_node

      def initialize(current_xml_node)
        if current_xml_node.is_a?(Nokogiri::XML::Node)
          @current_xml_node = current_xml_node
        else
          @current_xml_node = nil
        end
      end

      def inspect
        self.to_s
      end

      def self.get_xml_node_set(parent_xml_node, xpath, namespaces)
        raise ArgumentError, 'The xml_node variable have to be a Nokogiri::XML::Node type.' unless parent_xml_node.is_a?(Nokogiri::XML::Node)
        raise ArgumentError, 'The xpath variable cannot be blank.' if xpath.blank?

        parent_xml_node.xpath(xpath, namespaces)
      end

      # Creates a method to represents xml element
      # Usages:
      # => xml_element :name, 'xmlns:Name', :string
      def self.xml_element(method_name, xpath = '.', data_type = :string)
        define_method(method_name) {
          variable_name = "@#{method_name}"
          unless (instance_variables.include?(variable_name))
            if @current_xml_node
              node_set = self.class.get_xml_node_set(@current_xml_node, xpath, @current_xml_node.namespaces)
              instance_variable_set(variable_name.to_sym, self.class.xml_element_to_object(node_set.first, data_type))
            else
              instance_variable_set(variable_name.to_sym, nil)
            end
          end
          instance_variable_get(variable_name.to_sym)
        }
      end

      # Creates a method to represents xml collection
      # Usages:
      # => xml_collection :tasks, EasyDataTemplates::MsProject2010::Tasks
      def self.xml_collection(method_name, klass)
        define_method(method_name) {
          variable_name = "@#{method_name}"
          unless (instance_variables.include?(variable_name))
            klass_instance = klass.new(@current_xml_node)
            if klass_instance && !klass_instance.current_xml_node.nil?
              instance_variable_set(variable_name.to_sym, klass_instance)
            else
              instance_variable_set(variable_name.to_sym, nil)
            end
          end
          instance_variable_get(variable_name.to_sym)
        }
      end

      # Creates a methods to represents xml elements
      # Usages:
      # => xml_elements 'xmlns:Name', '@projectId', :type => :string
      def self.xml_elements(*xpaths)
        return if xpaths.blank?

        options = xpaths.last.is_a?(Hash) && xpaths.pop
        if options && options[:type]
          data_type = options[:type]
        end
        data_type ||= :string

        xpaths.each do |xpath|
          name = xpath.gsub(/@|.+:/, '').underscore
          xml_element(name, xpath, data_type)
        end
      end

      def self.xml_element_to_object(xml_node, data_type = :string)
        return nil unless xml_node.is_a?(Nokogiri::XML::Node)

        case data_type
        when :string
          return xml_element_to_string(xml_node)
        when :integer
          return xml_element_to_integer(xml_node)
        when :float
          return xml_element_to_float(xml_node)
        when :datetime
          return xml_element_to_datetime(xml_node)
        when :date
          return xml_element_to_date(xml_node)
        end

        return nil
      end

      def self.xml_node_value(xml_node)
        if xml_node.is_a?(Nokogiri::XML::Element)
          xml_element_value(xml_node.children.first) unless xml_node.children.blank?
        elsif xml_node.is_a?(Nokogiri::XML::Attr)
          xml_attribute_value(xml_node)
        end
      end

      def self.xml_element_value(xml_element)
        xml_element.text
      end

      def self.xml_attribute_value(xml_attr)
        xml_attr.value
      end

      def self.xml_element_to_string(xml_node)
        v = xml_node_value(xml_node)
        v.nil? ? nil : v.to_s
      end

      def self.xml_element_to_integer(xml_node)
        v = xml_node_value(xml_node)
        v.nil? ? nil : v.to_i
      end

      def self.xml_element_to_float(xml_node)
        v = xml_node_value(xml_node)
        v.nil? ? nil : v.to_f
      end

      def self.xml_element_to_datetime(xml_node)
        v = xml_node_value(xml_node)
        v.nil? ? nil : begin; v.to_datetime; rescue; return nil; end
      end

      def self.xml_element_to_date(xml_node)
        v = xml_node_value(xml_node)
        v.nil? ? nil : begin; v.to_date; rescue; return nil; end
      end

    end
  end
end
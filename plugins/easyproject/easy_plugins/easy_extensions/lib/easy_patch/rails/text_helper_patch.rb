require 'nokogiri'

module EasyPatch
  module TextHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def truncate_html(text, max_length, ellipsis = '...')
          ellipsis_length = ellipsis.length
          doc = Nokogiri::HTML::DocumentFragment.parse(text)
          content_length = doc.inner_text.length
          actual_length = max_length - ellipsis_length
          (content_length > actual_length ? doc.truncate(actual_length).delete_empty_node.inner_html + ellipsis : text.to_s).html_safe
        end

      end

    end

    module InstanceMethods

    end

  end

  module NokogiriTruncator
    module NodeWithChildren
      def truncate(max_length)
        return self if inner_text.length <= max_length
        truncated_node = self.dup
        truncated_node.children.remove

        self.children.each do |node|
          remaining_length = max_length - truncated_node.inner_text.length

          if remaining_length <= 0
            self.children.remove
            break
          end
          truncated_node.add_child node.truncate(remaining_length)
        end
        truncated_node
      end

      def delete_empty_node
        self.children.each do |child|
          if child.children.blank? && child.inner_text.blank?
            if child.parent.children.count > 1
              child.remove
            else
              child.parent.remove
            end
          else
            child.delete_empty_node
          end
        end

        return self
      end
    end

    module TextNode
      def truncate(max_length)
        if RUBY_VERSION < '1.9'
          Nokogiri::XML::Text.new(content.utf8_safe_split(max_length - 1)[0], parent)
        else
          Nokogiri::XML::Text.new(content.first(max_length - 1), parent)
        end
      end

      def delete_empty_node
        return self
      end
    end

  end

end
EasyExtensions::PatchManager.register_rails_patch ['Nokogiri::HTML::DocumentFragment', 'Nokogiri::XML::Element', 'Nokogiri::XML::Comment'], 'EasyPatch::NokogiriTruncator::NodeWithChildren'
EasyExtensions::PatchManager.register_rails_patch 'Nokogiri::XML::Text', 'EasyPatch::NokogiriTruncator::TextNode'

EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::TextHelper', 'EasyPatch::TextHelperPatch'

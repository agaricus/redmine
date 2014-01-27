# encoding: utf-8
module EasyPatch
  module RedminePaginationHelperPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :pagination_links_each, :easy_extensions

      end
    end

    module InstanceMethods

      def pagination_links_each_with_easy_extensions(paginator, count=nil, options={}, &block)
        #options.assert_valid_keys :per_page_links, :next_link_params

        per_page_links = options.delete(:per_page_links)
        per_page_links = false if count.nil?
        page_param = paginator.page_param
        options[:next_link_params] ||= {}
        if options[:query] && options[:entities]
          if options[:query].grouped? && options[:entities].any?
            if options[:entities].is_a?(Hash)
              previous_group = options[:entities].keys.last
            else
              previous_group = options[:query].group_by_column.value(options[:entities].last)
            end
            options[:next_link_params].merge!(:previous_group => previous_group.to_param.to_s)
          end
        end

        html = ''
        if paginator.previous_page
          # \xc2\xab(utf-8) = &#171;
          text = "\xc2\xab " + l(:label_previous)
          html << yield(text, {page_param => paginator.previous_page}, :class => 'previous') + ' '
        end

        previous = nil
        paginator.linked_pages.each do |page|
          if previous && previous != page - 1
            html << content_tag('span', '...', :class => 'spacer') + ' '
          end
          if page == paginator.page
            html << content_tag('span', page.to_s, :class => 'current page')
          else
            html << yield(page.to_s, {page_param => page}, :class => 'page')
          end
          html << ' '
          previous = page
        end

        if paginator.next_page
          # \xc2\xbb(utf-8) = &#187;
          text = l(:label_next) + " \xc2\xbb"
          html << yield(text, {page_param => paginator.next_page}.merge(options[:next_link_params]), :class => 'next') + ' '
        end

        html << content_tag('span', "(#{paginator.first_item}-#{paginator.last_item}/#{paginator.item_count})", :class => 'items') + ' '

        if per_page_links != false && links = per_page_links(paginator, &block)
          html << content_tag('span', links.to_s, :class => 'per-page')
        end

        html.html_safe
      end
    end

  end
end
Redmine::Pagination::Helper.send(:include, EasyPatch::RedminePaginationHelperPatch)

module EasyPatch
  module PaginationPatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize, :easy_extensions
        alias_method_chain :page_count, :easy_extensions
        alias_method_chain :[], :easy_extensions

      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(controller, item_count, items_per_page, current_page=1)
        @show_all = (items_per_page == nil)
        raise ArgumentError, 'must have at least one item per page' if !@show_all && items_per_page <= 0

        @controller = controller
        @item_count = item_count || 0
        @items_per_page = items_per_page
        @pages = {}

        self.current_page = current_page
      end

      def page_count_with_easy_extensions
        @page_count ||= (@show_all || @item_count.zero?) ? 1 : (q,r=@item_count.divmod(@items_per_page); r==0? q : q+1)
      end

      define_method('[]_with_easy_extensions') do |number|
        @pages[number] ||= ActionController::Pagination::Paginator::Page.new(self, number, @show_all)
      end

    end

  end
end
#ActionController::Pagination::Paginator.send(:include, EasyPatch::ClassicPaginationPaginatorPatch)

module EasyPatch
  module ClassicPaginationPaginatorPagePatch
    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :initialize, :easy_extensions
        alias_method_chain :offset, :easy_extensions
        alias_method_chain :first_item, :easy_extensions
        alias_method_chain :last_item, :easy_extensions

      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(paginator, number, show_all = false)
        @paginator = paginator
        @number = number.to_i
        @number = 1 unless @paginator.has_page_number? @number
        @show_all = show_all
      end

      def offset_with_easy_extensions
        (@show_all == true) ? nil : @paginator.items_per_page * (@number - 1)
      end

      def first_item_with_easy_extensions
        offset.to_i + 1
      end

      def last_item_with_easy_extensions
        (@show_all == true) ? @paginator.item_count : [@paginator.items_per_page * @number, @paginator.item_count].min
      end

    end

  end
end
#EasyExtensions::PatchManager.register_other_patch 'ActionController::Pagination::Paginator::Page', 'EasyPatch::ClassicPaginationPaginatorPagePatch'

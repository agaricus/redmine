require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupVersion < EasyLookup

      def attributes
        [[l(:field_name), 'name'], [l(:label_link_with, :attribute => l(:field_name)), 'link_with_name']]
      end

    end
  end
end
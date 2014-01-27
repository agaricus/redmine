require 'easy_extensions/easy_lookups/easy_lookup'

module EasyExtensions
  module EasyLookups
    class EasyLookupIssue < EasyLookup

      def attributes
        [[l(:field_subject), 'subject'], [l(:label_link_with, :attribute => l(:field_subject)), 'link_with_subject']]
      end

    end
  end
end
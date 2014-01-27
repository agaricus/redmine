module BulkTimeEntriesHelper 

  def grouped_options_for_issues(issues, selected, user=nil)
    closed_issues, open_issues = *issues.partition {|issue| issue.closed?}
    user ||= User.current

    html = '<option></option>'
    html << labeled_option_group_from_collection_for_select(l(:label_open_issues_plural), open_issues, selected, true, user)
    html << labeled_option_group_from_collection_for_select(l(:label_closed_issues_plural), closed_issues, selected, true, user)
    html
  end

  def labeled_option_group_from_collection_for_select(label, collection, selected, mygroup, user=nil)
    user ||= User.current
    html = ''
    if collection.any?
      html << "<optgroup label='#{label}'>"
      # debugger
      if mygroup
        my_collection, other_collection = *collection.partition {|issue| issue.assigned_to == user}
        html << labeled_option_group_from_collection_for_select("&nbsp;&nbsp;#{l(:label_my_issues_plural)}", my_collection, selected, false)
        html << labeled_option_group_from_collection_for_select("&nbsp;&nbsp;#{l(:label_other_issues_plural)}", other_collection, selected, false)
      else
        html << options_from_collection_for_select(collection, :id, :to_s, selected)
      end
      html << "</optgroup>"
    end
    html
  end
  
  def delete_unsafe_combobox_attribute(attributes)
    return if attributes.blank?
    attributes.delete_if{|k,v| k =~ Regexp.new(/^.*_new_value$/) }
  end
end

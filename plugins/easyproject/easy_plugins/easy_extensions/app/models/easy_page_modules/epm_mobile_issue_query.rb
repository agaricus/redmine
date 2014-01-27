class EpmMobileIssueQuery < EpmIssueQuery

  def show_path
    @show_path ||= "easy_page_modules/mobile_modules/#{module_name}_show"
  end

  def edit_path
    @edit_path ||= "easy_page_modules/mobile_modules/#{module_name}_edit"
  end

  def get_show_data(settings, user, page_context = {})
    result = super
    result[:available_ending_buttons] = (settings['mobile_issue_query_end_buttons'] || []).map(&:to_sym)

    return result
  end

end

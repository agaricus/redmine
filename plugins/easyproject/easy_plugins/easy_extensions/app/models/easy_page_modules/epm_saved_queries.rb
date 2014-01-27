class EpmSavedQueries < EasyPageModule

  def category_name
    @category_name ||= 'others'
  end

  def get_show_data(settings, user, page_context = {})
    public, personal = Hash.new, Hash.new
    queries = EasyQuery.registered_subclasses.keys.select{ |query_class| !settings['queries'] || settings['queries'].include?(query_class.name.underscore) }
    queries.each do |query_class|
      personal[query_class] = query_class.private_queries(user) if settings['saved_personal_queries']
      public[query_class] = query_class.public_queries(user) if settings['saved_public_queries'] && user.easy_user_type == User::EASY_USER_TYPE_INTERNAL
    end

    return {:public => public, :personal => personal, :selected => queries }
  end

  def get_edit_data(settings, user, page_context={})
    queries = EasyQuery.registered_subclasses.keys.collect{|q| q.name.underscore }
    return {:queries => queries}
  end

end

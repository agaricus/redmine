module EasyQuerySettingsHelper
  def easy_query_settings_tabs
    tabs = Array.new
    EasyQuery.registered_subclasses.each do |easy_query, options|
      tabs << {
        :name => easy_query.name.underscore.to_s,
        :partial => options[:easy_query_settings_partial] || 'easy_query_settings/setting',
        :label => l(easy_query.name.underscore, :scope => [:easy_query, :name], :default => h(easy_query.name.underscore)),
        :redirect_link => true,
        :url => {:controller => 'easy_query_settings', :action => 'setting', :tab => easy_query.name.underscore}
      }
    end

    return tabs
  end

end
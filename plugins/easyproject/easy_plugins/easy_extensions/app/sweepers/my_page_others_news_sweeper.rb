class MyPageOthersNewsSweeper < ActionController::Caching::Sweeper
#  observe News, Comment
#
#  def after_create(cached_item)
#    expire_cache_for(cached_item)
#  end
#
#  def after_update(cached_item)
#    expire_cache_for(cached_item)
#  end
#
#  def after_destroy(cached_item)
#    expire_cache_for(cached_item)
#  end
#
#  private
#
#  def expire_cache_for(cached_item)
#    news = case cached_item.class.name
#    when 'News'
#      cached_item
#    when 'Comment'
#      return unless cached_item.commented.is_a?(News)
#      cached_item.commented
#    end
#
#    users = []
#    users.concat(news.project.members)
#    users.concat(User.find(:all, :conditions => {:admin => true}))
#    users = users.compact.collect{|u| u.id}.uniq.each do |user_id|
#      expire_fragment("my_page_others_news_user_#{user_id}")
#    end
#  end
#
end
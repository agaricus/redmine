class MyPageMyProjectsSimpleSweeper < ActionController::Caching::Sweeper
#  observe Project, Member
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
#    if cached_item.is_a?(Project)
#      users = []
#      if cached_item.root.nil?
#        users.concat(cached_item.self_and_descendants.collect(&:members).flatten.uniq.compact)
#      else
#        users.concat(cached_item.root.self_and_descendants.collect(&:members).flatten.uniq.compact)
#      end
#      users.concat(User.find(:all, :conditions => {:admin => true}))
#      users = users.compact.collect{|u| u.id}.uniq.each do |user_id|
#        expire_fragment("my_page_my_projects_simple_user_#{user_id}")
#      end
#    elsif cached_item.is_a?(Member) && !cached_item.user.nil?
#      expire_fragment("my_page_my_projects_simple_user_#{cached_item.user.id}")
#    end
#  end
#
end
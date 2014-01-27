class MyPageOthersDocumentsSweeper < ActionController::Caching::Sweeper
#  observe Document, Attachment
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
#    document = case cached_item.class.name
#    when 'Document'
#      cached_item
#    when 'Attachment'
#      return unless cached_item.container.is_a?(Document)
#      cached_item.container
#    end
#
#    users = []
#    users.concat(document.project.members)
#    users.concat(User.find(:all, :conditions => {:admin => true}))
#    users = users.compact.collect{|u| u.id}.uniq.each do |user_id|
#      expire_fragment("my_page_others_documents_user_#{user_id}")
#    end
#  end
#
end
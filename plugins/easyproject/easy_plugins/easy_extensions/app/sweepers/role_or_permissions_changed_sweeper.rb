class RoleOrPermissionsChangedSweeper < ActionController::Caching::Sweeper
  observe Role

  def after_create(cached_item)
    expire_cache_for(cached_item)
  end

  def after_update(cached_item)
    expire_cache_for(cached_item)
  end

  def after_destroy(cached_item)
    expire_cache_for(cached_item)
  end

  private

  def expire_cache_for(cached_item)
    if cached_item.is_a?(Role)
      removed_permissions = (cached_item.permissions_was || []) - (cached_item.permissions || [])
      added_permissions = (cached_item.permissions || []) - (cached_item.permissions_was || [])
      
      removed_permissions.each{|p| permission_changed(cached_item, p)}
      added_permissions.each{|p| permission_changed(cached_item, p)}
    end
  end

  def permission_changed(cached_item, permission_name)
    m = :"permission_changed_#{permission_name}"
    if respond_to?(m)
      send(m, cached_item)
    end
  end

  def permission_changed_edit_issue_notes(cached_item)
    #expire_fragment(/issues\/journal\/notes\/journals\/#{cached_item.id}-/)
  end

  def permission_changed_edit_own_issue_notes(cached_item)
    #expire_fragment(/issues\/journal\/notes\/journals\/#{cached_item.id}-/)
  end

end
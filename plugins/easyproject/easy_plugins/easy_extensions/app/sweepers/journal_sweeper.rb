class JournalSweeper < ActionController::Caching::Sweeper
  observe Journal

  def after_update(cached_item)
    expire_cache_for(cached_item)
  end

  private

  def expire_cache_for(cached_item)
    if cached_item.is_a?(Journal)
      expire_fragment(/issues\/journal\/notes\/journals\/#{cached_item.id}-/)
    end
  end

end
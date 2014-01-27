class EasyRakeTaskEasyMoneyProjectCache < EasyRakeTask

  def execute
    Project.non_templates.has_module(:easy_money).all.each do |p|

      easy_money_project_cache = p.easy_money_project_cache || p.build_easy_money_project_cache

      easy_money_project_cache.update_from_project!(p)
    end

    return true
  end

end

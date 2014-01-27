class EasyPageModulesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def used_modules
    @modules = EasyPageModule.find(:all, :include => [{:available_in_pages => [:page_definition, :all_modules]}]).sort_by(&:translated_name)
  end

end

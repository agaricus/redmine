class EasyPageLayoutController < ApplicationController

  helper :issues
  include IssuesHelper
  helper :users
  include UsersHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :projects
  include ProjectsHelper
  helper :timelog
  include TimelogHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :attachments
  include AttachmentsHelper
  helper :avatars
  include AvatarsHelper
  helper :sort
  include SortHelper
  helper :easy_page_modules
  include EasyPageModulesHelper

  before_filter :find_project
  before_filter :find_page, :only => [:add_module, :order_module, :save_module]
  before_filter :find_zone, :only => [:add_module, :order_module]

  def add_module
    begin
      available_module = EasyPageAvailableModule.find(params[:module_id])
    rescue ActiveRecord::RecordNotFound
      render_404
      return
    end

    user = User.find(params[:user_id]) unless params[:user_id].nil?
    user_id = user.id unless user.nil?
    tab = params[:t].to_i
    tab = 1 if tab <= 0
    page_tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]
    page_tab ||= EasyPageUserTab.where(:page_id => @page.id, :user_id => user_id, :entity_id => params[:entity_id], :position => tab).first

    page_module = EasyPageZoneModule.new(:easy_pages_id => @page.id, :easy_page_available_zones_id => @zone.id, :easy_page_available_modules_id => available_module.id,
      :user_id => user_id, :entity_id => params[:entity_id], :tab => tab, :tab_id => (page_tab && page_tab.id), :settings => available_module.module_definition.default_settings || HashWithIndifferentAccess.new)
    page_module.save!
    page_module.move_to_top

    render_single_easy_page_module(page_module, nil, @page, user, nil, nil, true, true, {})
  end

  def remove_module
    pzm = EasyPageZoneModule.find(params[:uuid].dasherize)
    pzm.destroy if pzm

    render :nothing => true
  end

  def order_module
    remaining_modules_in_zone = (params["list-#{@zone.zone_definition.zone_name.dasherize}"] || [])
    tab = params[:t].to_i
    tab = 1 if tab <= 0

    #EasyPageZoneModule.transaction do
      if (remaining_modules_in_zone.size > 0)
        scope = EasyPageZoneModule.where(:easy_pages_id => @page.id)
        scope = scope.where(:easy_page_available_zones_id => @zone.id)
        scope = scope.where(:tab => tab)
        scope = scope.where("#{EasyPageZoneModule.table_name}.uuid NOT IN (?)", remaining_modules_in_zone)

        if params[:user_id].blank?
          scope = scope.where(:user_id => nil)
        else
          scope = scope.where(:user_id => params[:user_id].to_i)
        end

        if params[:entity_id].blank?
          scope = scope.where(:entity_id => nil)
        else
          scope = scope.where(:entity_id => params[:entity_id].to_i)
        end

        scope.update_all(:easy_page_available_zones_id => -1)
      end

      position = 0
      remaining_modules_in_zone.each do |uuid|
        position += 1
        EasyPageZoneModule.where(:uuid => uuid).update_all(:easy_page_available_zones_id => @zone.id, :position => position)
      end

      EasyPageZoneModule.where(:easy_pages_id => @page.id).where(:easy_page_available_zones_id => -1).update_all(:easy_page_available_zones_id => @page.zones.first.id)
    #end

    render :nothing => true
  end

  def save_module
    @page.user_modules(params[:user_id], params[:entity_id], nil, :all_tabs => true).each do |zone_name, user_modules|
      user_modules.each do |user_module|
        next unless params[user_module.module_name]
        user_module.settings = params[user_module.module_name]
        user_module.save
      end
    end

    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end

    EasyPageZoneModule.create_from_page_template(page_template, params[:user_id], params[:entity_id])

    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template_selecting_projects
  end

  def layout_from_template_selected_projects
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end
    projects = Project.find(params[:projects])

    projects.each do |project|
      EasyPageZoneModule.create_from_page_template(page_template, nil, project.id)
    end

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template_selecting_users
    @users = User.active.all.sort_by(&:name)
  end

  def layout_from_template_selected_users
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end

    if params[:users]
      User.where(:id => params[:users]).each do |user|
        EasyPageZoneModule.create_from_page_template(page_template, user.id, params[:entity_id])
      end
    end

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def layout_from_template_to_all
    begin
      page_template = EasyPageTemplate.find(params[:page_template_id].to_i)
    rescue ActiveRecord::RecordNotFound
      redirect_to params[:back_url]
      return
    end
    page = page_template.page_definition
    actions = params[:actions].to_s.split(',')

    User.all.each do |user|
      EasyPageZoneModule.create_from_page_template(page_template, user.id, params[:entity_id])
    end if actions.include?('users')

    Redmine::Hook.call_hook(:controller_easy_page_layout_layout_from_template_to_all, { :page_template => page_template, :page => page, :actions => actions})

    flash[:notice] = l(:notice_template_successful_applied)
    redirect_back_or_default(:controller => 'my', :action => 'page')
  end

  def get_tab_content
    @page = EasyPage.find(params[:page_id]) if params[:page_id]
    @tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]
    user = User.find(params[:user_id]) if params[:user_id]

    @layout_style = @page.layout_path.match(/\/?([^\/]+)$/)[1]

    render_action_as_easy_tab_content(@tab, @page, user, params[:entity_id], nil, true)
  end

  def show_tab
    @tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]
    @selected_tab = params[:t].to_i if params[:t]
    is_preloaded = params[:is_preloaded].to_s.to_boolean

    if @tab
      respond_to do |format|
        format.html{render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => {:tab => @tab, :editable => true, :selected_tab => @selected_tab, :is_preloaded => is_preloaded}}
        format.js{ @is_preloaded = is_preloaded }
      end
    else
      render :nothing => true
    end
  end

  def add_tab
    page = EasyPage.find(params[:page_id])
    user = User.find(params[:user_id]) if params[:user_id]
    entity_id = params[:entity_id]

    @tab = EasyPageUserTab.create(:page_id => page.id, :user_id => (user && user.id), :entity_id => entity_id, :name => l(:label_easy_page_tab_default_name, :count => EasyPageUserTab.page_tabs(page, (user && user.id), entity_id).size + 1))

    @tabs = EasyPageUserTab.page_tabs(page, (user && user.id), entity_id)
    unless @tabs.detect{|tab| tab.id != @tab.id}
      EasyPageZoneModule.where(:easy_pages_id => page.id, :user_id => params[:user_id], :entity_id => entity_id).update_all(:tab_id => @tab.id)
    end


    respond_to do |format|
      format.html {
        if @tabs && @tabs.size > 0
          render(:partial => 'common/easy_page_editable_tabs', :locals => {:tabs => @tabs, :editable => true})
        else
          render :nothing => true
        end
      }
      format.js{
        if @tabs && @tabs.size > 0
          @page = page
          @layout_style = @page.layout_path.match(/\/([^\/]+)$/)[1]
          render_action_as_easy_tab_content(@tab, page, user, entity_id, nil, true)
        else
          render :nothing => true
        end
      }
    end
  end

  def edit_tab
    tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]

    if tab
      render :partial => 'common/easy_page_editable_tabs_inline_edit', :locals => {:tab => tab, :editable => true, :is_preloaded => params[:is_preloaded]}
    else
      render :nothing => true
    end
  end

  def save_tab
    tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]
    if params[:t]
      selected_tab = params[:t].to_i
    end
    is_preloaded = params[:is_preloaded].to_s.to_boolean

    if tab
      tab.name = params[:name] if params[:name]
      tab.reorder_to_position = params[:reorder_to_position] if params[:reorder_to_position]
      tab.save
      respond_to do |format|
        format.html {render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => {:tab => tab, :editable => true, :selected_tab => selected_tab, :is_preloaded => is_preloaded }}
        format.js {@tab = tab; @selected_tab = selected_tab; @is_preloaded = is_preloaded}
        format.json {render :nothing => true}
      end
    else
      render :nothing => true
    end
  end

  def remove_tab
    tab = EasyPageUserTab.find(params[:tab_id]) if params[:tab_id]
    if tab
      next_pos = tab.position - 2
      EasyPageZoneModule.delete_modules(tab.page_definition, params[:user_id], params[:entity_id], tab.id)
      tab.destroy
    end

    page = EasyPage.find(params[:page_id])
    user = User.find(params[:user_id]) if params[:user_id]
    entity_id = params[:entity_id]

    tabs = EasyPageUserTab.page_tabs(page, (user && user.id), entity_id)
    
    if request.xhr?
      respond_to do |format|
        format.html {
          if tabs && tabs.size > 0
            selected_tab = params[:t].to_i
            selected_tab = 1 if selected_tab <= 0

            render(:partial => 'common/easy_page_editable_tabs', :locals => {:tabs => tabs, :editable => true, :selected_tab => selected_tab})
          else
            render :nothing => true
          end
        }
        format.js {
          if tabs.size > 0 && tab && tab.position == params[:t].to_i
            js_script = "PageLayout.tab_element.tabs( 'option', 'active', #{tab.position - 2} );"
          elsif tabs.size < 1
            original_url = CGI.unescape(params[:original_url])
            js_script = "PageLayout.tab_element.tabs('destroy'); window.location.href='#{original_url}';"
          end
          if js_script
            render :status => :ok, :text => js_script
          else
            render :nothing => true
          end
        }
      end
    else
      original_url = CGI.unescape(params[:original_url])
      original_url.gsub!(/tab=\d+/, '')
      redirect_to(original_url)
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page
    @page = EasyPage.find(params[:page_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_zone
    @zone = EasyPageAvailableZone.find(params[:zone_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
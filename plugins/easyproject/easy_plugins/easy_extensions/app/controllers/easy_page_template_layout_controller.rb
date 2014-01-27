class EasyPageTemplateLayoutController < ApplicationController

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
  helper :issue_relations
  include IssueRelationsHelper

  before_filter :find_project
  before_filter :find_page_template, :only => [:add_module, :order_module, :remove_module, :save_module]
  before_filter :find_zone, :only => [:add_module, :order_module]

  def add_module
    begin
      available_module = EasyPageAvailableModule.find(params[:module_id])
    rescue ActiveRecord::RecordNotFound
      render_404
      return
    end

    tab = params[:t].to_i
    tab = 1 if tab <= 0
    page_tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    page_tab ||= EasyPageTemplateTab.where(:page_template_id => @page_template.id, :entity_id => params[:entity_id], :position => tab).first

    template_module = EasyPageTemplateModule.new(:easy_page_templates_id => @page_template.id, :easy_page_available_zones_id => @zone.id, :easy_page_available_modules_id => available_module.id,
      :entity_id => params[:entity_id], :tab => tab, :tab_id => (page_tab && page_tab.id), :settings => available_module.module_definition.default_settings || HashWithIndifferentAccess.new)
    template_module.save!
    template_module.move_to_top

    page_params = create_page_params_for_easy_page_template(@page_template, @page, User.current, params[:entity_id], params[:back_url] || url_for(params), true)

    @easy_page_modules_data = {}
    @easy_page_modules_data[template_module.module_name] = template_module.get_edit_data(User.current)

    render :partial => "easy_page_layout/page_module_edit_container", :locals => { :page_params => page_params, :page_module => template_module }
  end

  def remove_module
    pzm = EasyPageTemplateModule.find(params[:uuid].dasherize)
    pzm.destroy if pzm

    render :nothing => true
  end

  def order_module
    remaining_modules_in_zone = (params["list-#{@zone.zone_definition.zone_name.dasherize}"] || [])
    tab = params[:t].to_i
    tab = 1 if tab <= 0

    #EasyPageTemplateModule.transaction do
      if (remaining_modules_in_zone.size > 0)
        scope = EasyPageTemplateModule.where(:easy_page_templates_id => @page_template.id)
        scope = scope.where(:easy_page_available_zones_id => @zone.id)
        scope = scope.where(:tab => tab)
        scope = scope.where(["#{EasyPageTemplateModule.table_name}.uuid NOT IN (?)", remaining_modules_in_zone])

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

        EasyPageTemplateModule.where(:uuid => uuid).update_all(:easy_page_available_zones_id => @zone.id, :position => position)
      end

      EasyPageTemplateModule.where(:easy_page_templates_id => @page_template.id).where(:easy_page_available_zones_id => -1).update_all(:easy_page_available_zones_id => @page_template.page_definition.zones.first.id)
    #end

    render :nothing => true
  end

  def save_module
    @page_template.template_modules(params[:entity_id]).each do |zone_name, template_modules|
      template_modules.each do |template_module|
        next unless params[template_module.module_name]
        template_module.settings = params[template_module.module_name] || {}
        template_module.save
      end
    end
    redirect_to params[:back_url]
  end

  def get_tab_content
    @page_template = EasyPageTemplate.find(params[:page_template_id])
    @tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    user = User.find(params[:user_id]) if params[:user_id]

    @layout_style = @page_template.page_definition.layout_path.match(/\/?([^\/]+)$/)[1] if

    render_action_as_easy_tab_content(@tab, @page_template, user, params[:entity_id], nil, true)
    render 'easy_page_layout/get_tab_content'
  end

  def show_tab
    @tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    @selected_tab = params[:t].to_i if params[:t]
    @is_preloaded = params[:is_preloaded].to_s.to_boolean

    if @tab
      respond_to do |format|
        format.html {
          render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => {:tab => @tab, :editable => true, :selected_tab => @selected_tab, :is_preloaded => @is_preloaded}
        }
        format.js {
          render 'easy_page_layout/show_tab'
        }
      end
    else
      render :nothing => true
    end
  end

  def add_tab
    page_template = EasyPageTemplate.find(params[:page_template_id])
    entity_id = params[:entity_id]

    @tab = EasyPageTemplateTab.create(:page_template_id => page_template.id, :entity_id => entity_id, :name => l(:label_easy_page_tab_default_name, :count => EasyPageTemplateTab.page_template_tabs(page_template, entity_id).size + 1))

    @tabs = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)
    unless @tabs.detect{|tab| tab.id != @tab.id}
      EasyPageTemplateModule.where(:easy_page_templates_id => page_template.id, :entity_id => entity_id).update_all(:tab_id => @tab.id)
    end

    @page = page_template.page_definition


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
          @layout_style = @page.layout_path.match(/\/?([^\/]+)$/)[1]
          render_action_as_easy_tab_content(@tab, page_template, nil, entity_id, nil, true)
          render 'easy_page_layout/add_tab'
        else
          render :nothing => true
        end
      }
    end
  end

  def edit_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]

    if tab
      render :partial => 'common/easy_page_editable_tabs_inline_edit', :locals => {:tab => tab, :editable => true, :is_preloaded => params[:is_preloaded]}
    else
      render :nothing => true
    end
  end

  def save_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    if params[:t]
      selected_tab = params[:t].to_i
    end

    if tab
      is_preloaded = params[:is_preloaded].to_s.to_boolean if params[:is_preloaded]
      tab.name = params[:name] if params[:name]
      tab.reorder_to_position = params[:reorder_to_position] if params[:reorder_to_position]
      tab.save

      respond_to do |format|
        format.html{
          render :partial => 'common/easy_page_editable_tabs_inline_show', :locals => {:tab => tab, :editable => true, :selected_tab => selected_tab}
        }
        format.js {
          @tab = tab; @selected_tab = selected_tab; @is_preloaded = is_preloaded
          render 'easy_page_layout/save_tab'
        }
      end
    else
      render :nothing => true
    end
  end

  def remove_tab
    tab = EasyPageTemplateTab.find(params[:tab_id]) if params[:tab_id]
    if tab
      next_pos = tab.position - 2
      EasyPageTemplateModule.delete_modules(tab.page_template_definition, params[:entity_id], tab.id)
      tab.destroy
    end

    page_template = EasyPageTemplate.find(params[:page_template_id])
    entity_id = params[:entity_id]

    tabs = EasyPageTemplateTab.page_template_tabs(page_template, entity_id)

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

  def find_page_template
    @page_template = EasyPageTemplate.find(params[:id])
    @page = @page_template.page_definition
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_zone
    @zone = EasyPageAvailableZone.find(params[:zone_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

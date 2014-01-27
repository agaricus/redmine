class EasyPageTemplatesController < ApplicationController

  before_filter :find_project
  before_filter :find_page, :except => [:move, :show_page_template, :edit_page_template]
  before_filter :find_template, :only => [:show, :edit, :update, :destroy, :move, :show_page_template, :edit_page_template]
  before_filter :find_page_from_template, :only => [:move, :show_page_template, :edit_page_template]
  #after_filter :change_layout, :except => [:show_page_template, :edit_page_template]
  before_filter :require_admin

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

  # GET /easy_page_templates/page/:page_id
  def index
    self.class.layout 'admin'
    @page_templates = @page.templates
  end

  # GET /easy_page_templates/:id
  # GET /easy_page_templates/:id/show
  def show
    self.class.layout 'admin'
  end

  # GET /easy_page_templates/page/:page_id/new
  def new
    self.class.layout 'admin'
    @page_template = EasyPageTemplate.new
  end

  # POST /easy_page_templates
  def create
    @page_template = EasyPageTemplate.new(params[:easy_page_template])

    respond_to do |format|
      if @page_template.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index', :page_id => @page.id ) }
      else
        format.html { render :action => "new", :page_id => @page.id }
      end
    end

  end

  # GET /easy_page_templates/page/:page_id/:id/edit
  def edit
    self.class.layout 'admin'
  end

  # PUT /easy_page_templates/:id
  def update
    respond_to do |format|
      if @page_template.update_attributes(params[:easy_page_template])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index', :page_id => @page.id ) }
        format.api {render_api_ok}
      else
        format.html { render :action => "edit", :page_id => @page.id }
        format.api  { render_validation_errors(@page_template) }
      end
    end
  end

  # DELETE /easy_page_templates/:id
  def destroy
    @page_template.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to( :action => 'index', :page_id => @page.id ) }
    end
  end

  # GET /easy_page_templates/:id/move
  # def move
  #   @page_template.update_attributes(params[:easy_page_template])
  #   redirect_to( :action => 'index', :page_id => @page.id )
  # end

  def show_page_template
    render_action_as_easy_page_template(@page_template, User.current, nil, url_for(:action=>'show_page_template', :id => @page_template.id), false)
  end

  def edit_page_template
    render_action_as_easy_page_template(@page_template, User.current, nil, url_for(:action=>'show_page_template', :id => @page_template.id), true)
  end

  private

  def find_project
    @project = Project.find(params[:project_id]) unless params[:project_id].blank?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_template
    #@template is reserved variable!
    @page_template = EasyPageTemplate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page
    @page = params[:page_id].nil? ? EasyPage.find((params[:easy_page_template] ? params[:easy_page_template][:easy_pages_id] : nil)) : EasyPage.find(params[:page_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page_from_template
    @page = @page_template.page_definition unless @page_template.nil?
  end

  def change_layout
    self.class.layout 'admin'
  end

end

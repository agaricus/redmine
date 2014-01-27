class EasyPageZonesController < ApplicationController
  layout 'admin'

  before_filter :find_project
  before_filter :find_page
  before_filter :find_zone, :only => [:show, :edit, :update]
  before_filter :find_page_zone, :only => [:destroy]

  # GET /easy_page_zones
  def index
    @zones = EasyPageZone.all
  end

  # GET /easy_page_zones/page/:id
  def page_index
    @zones = @page.zones
  end

  # GET /easy_page_zones/:id
  # GET /easy_page_zones/:id/show
  def show
  end

  # GET /easy_page_zones/new
#  def new
#    @zone = EasyPageZone.new
#  end

  # POST /easy_page_zones
  def create
    @zone = EasyPageZone.new(params[:easy_page_zone])

    respond_to do |format|
      if @zone.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "new" }
      end
    end

  end

  # GET /easy_page_zones/:id/edit
  def edit
  end

  # PUT /easy_page_zones/:id
  def update
    respond_to do |format|
      if @zone.update_attributes(params[:easy_page_zone])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /easy_page_zones/:id
  def destroy
    @zone.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to( :action => 'page_index', :page_id => @page.id ) }
    end
  end

  def assign_zone
    if request.get?
      @zones = @page.unassigned_zones
    else
      zone_id = params["zone_id"].to_i

      if zone_id > 0
        EasyPageAvailableZone.create :easy_pages_id => @page.id, :easy_page_zones_id => zone_id
      end

      redirect_to :action => 'page_index', :page_id => @page.id
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
    @zone = EasyPageZone.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page_zone
    @zone = EasyPageAvailableZone.find(params[:zone_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

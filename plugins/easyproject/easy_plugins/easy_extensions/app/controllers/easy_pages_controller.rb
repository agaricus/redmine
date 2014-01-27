class EasyPagesController < ApplicationController
  layout 'admin'

  before_filter :find_page, :only => [:show, :edit, :update, :destroy]
  before_filter :find_page2, :only => [:templates]

  # GET /easy_pages
  def index
    #@pages = EasyPage.all
    #@pages = [EasyPage.page_my_page]
    @pages = EasyPage.all
  end

  # GET /easy_pages/:id
  # GET /easy_pages/:id/show
  def show
  end

  # GET /easy_pages/new
  def new
    @page = EasyPage.new
  end

  # POST /easy_pages
  def create
    @page = EasyPage.new(params[:easy_page])

    respond_to do |format|
      if @page.save
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "new" }
      end
    end

  end

  # GET /easy_pages/:id/edit
  def edit
  end

  # PUT /easy_pages/:id
  def update
    respond_to do |format|
      if @page.update_attributes(params[:easy_page])
        flash[:notice] = l(:notice_successful_update)
        format.html { redirect_to( :action => 'index' ) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /easy_pages/:id
  def destroy
    @page.destroy

    respond_to do |format|
      flash[:notice] = l(:notice_successful_delete)
      format.html { redirect_to( :action => 'index' ) }
    end
  end

  # GET /easy_pages/templates/page/:page_id
  def templates
    @templates = @page.templates
  end


private

  def find_page
    @page = EasyPage.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_page2
    @page = EasyPage.find(params[:page_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

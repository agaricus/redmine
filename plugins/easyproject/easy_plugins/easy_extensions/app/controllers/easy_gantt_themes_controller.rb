class EasyGanttThemesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def index
    @gantt_themes = EasyGanttTheme.all
  end

  def new
    @gantt_theme = EasyGanttTheme.new
  end

  def create
    @gantt_theme = EasyGanttTheme.new
    @gantt_theme.safe_attributes = params[:easy_gantt_theme]
    @gantt_theme.save_attachments({'first' => {'file' => params[:easy_gantt_theme][:logo]}})
    if @gantt_theme.save
      redirect_to :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @gantt_theme = EasyGanttTheme.find(params[:id])
  end

  def update
    @gantt_theme = EasyGanttTheme.find(params[:id])
    @gantt_theme.safe_attributes = params[:easy_gantt_theme]
    @gantt_theme.save_attachments({'first' => {'file' => params[:easy_gantt_theme][:logo]}})
    if @gantt_theme.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def destroy
    @gantt_theme = EasyGanttTheme.find(params[:id])
    @gantt_theme.destroy
    redirect_to :action => 'index'
  end
end

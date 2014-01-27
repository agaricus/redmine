class EasyUserTimeCalendarHolidaysController < ApplicationController
  layout 'admin'

  before_filter { |c| c.require_admin_or_lesser_admin(:working_time) }
  before_filter :find_calendar
  before_filter :find_holiday, :only => [:show, :edit, :update, :destroy]

  def index
    @holidays = @easy_user_working_time_calendar.holidays

    respond_to do |format|
      format.html
    end
  end

  def show
    respond_to do |format|
      format.html
    end
  end

  def new
    @easy_user_time_calendar_holiday = EasyUserTimeCalendarHoliday.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_user_time_calendar_holiday = EasyUserTimeCalendarHoliday.new(params[:easy_user_time_calendar_holiday])

    if @easy_user_time_calendar_holiday.save
      respond_to do |format|
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to :action => 'index', :calendar_id => @easy_user_working_time_calendar }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
  end

  def update
    if @easy_user_time_calendar_holiday.update_attributes(params[:easy_user_time_calendar_holiday])
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to :action => 'index', :calendar_id => @easy_user_working_time_calendar }
      end
    else
      respond_to do |format|
        format.html { render :action => 'edit' }
      end
    end
  end

  def destroy
    @easy_user_time_calendar_holiday.destroy
    flash[:notice] = l(:notice_successful_delete)

    respond_to do |format|
      format.html { redirect_to :action => 'index', :calendar_id => @easy_user_working_time_calendar }
    end
  end

  private

  def find_calendar
    @easy_user_working_time_calendar = EasyUserTimeCalendar.find(params[:calendar_id], :conditions => {:user_id => nil, :parent_id => nil})
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_holiday
    @easy_user_time_calendar_holiday = @easy_user_working_time_calendar.holidays.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

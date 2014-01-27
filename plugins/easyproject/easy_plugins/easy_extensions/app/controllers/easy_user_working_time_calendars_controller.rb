class EasyUserWorkingTimeCalendarsController < ApplicationController
  layout 'admin'

  before_filter { |c| c.require_admin_or_lesser_admin(:working_time) }
  before_filter :find_calendar, :except => [:index, :new, :create, :assign_to_user]
  before_filter :prepare_variables, :only => [:show, :inline_show, :inline_edit, :inline_update]
  before_filter :find_user, :only => [:assign_to_user]

  def index
    @easy_user_working_time_calendars = EasyUserWorkingTimeCalendar.templates

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
    @easy_user_working_time_calendar = EasyUserWorkingTimeCalendar.new

    if params[:inherit]
      parent = EasyUserWorkingTimeCalendar.find(params[:inherit])
      @easy_user_working_time_calendar.parent_id = parent.id
      @easy_user_working_time_calendar.default_working_hours = parent.default_working_hours
      @easy_user_working_time_calendar.first_day_of_week = parent.first_day_of_week
    end

    respond_to do |format|
      format.html
    end
  end

  def create
    @easy_user_working_time_calendar = EasyUserWorkingTimeCalendar.new(params[:easy_user_working_time_calendar])

    if @easy_user_working_time_calendar.save

      unless params[:inherit].blank?
        inherit_from = EasyUserWorkingTimeCalendar.find(params[:inherit])

        if inherit_from && params[:copy_exceptions]
          @easy_user_working_time_calendar.exceptions << inherit_from.exceptions.collect{|e| e.dup}
        end

        if inherit_from && params[:copy_holidays]
          @easy_user_working_time_calendar.holidays << inherit_from.holidays.collect{|h| h.dup}
        end
      end

      respond_to do |format|
        flash[:notice] = l(:notice_successful_create)
        format.html { redirect_to :action => 'index' }
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
    if @easy_user_working_time_calendar.update_attributes(params[:easy_user_working_time_calendar])
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to params[:back_url] || {:action => 'index'} }
        format.api {render_api_ok}
      end
    else
      respond_to do |format|
        format.html do
          if params[:back_url].blank?
            render :action => 'edit'
          else
            flash[:error] = @easy_user_working_time_calendar.errors.full_messages.join('<br/>').html_safe
            redirect_back_or_default(:action => 'edit', :id => @easy_user_working_time_calendar)
          end
        end
        format.api  { render_validation_errors(@easy_user_working_time_calendar) }
      end
    end
  end

  def destroy
    @easy_user_working_time_calendar.destroy unless @easy_user_working_time_calendar.builtin?
    flash[:notice] = l(:notice_successful_delete)

    respond_to do |format|
      format.html { redirect_to :action => 'index' }
    end
  end

  def inline_show
    respond_to do |format|
      format.js
    end
  end

  def inline_edit
    respond_to do |format|
      format.js
    end
  end

  def inline_update
    if (@working_hours == 0.0 && (@easy_user_working_time_calendar.weekend?(@day) || @easy_user_working_time_calendar.holiday?(@day))) ||
        (@working_hours == @easy_user_working_time_calendar.default_working_hours && (!@easy_user_working_time_calendar.weekend?(@day) && !@easy_user_working_time_calendar.holiday?(@day)))
      exc = EasyUserTimeCalendarException.find(:first, :conditions => ["#{EasyUserTimeCalendarException.table_name}.calendar_id = ? AND #{EasyUserTimeCalendarException.table_name}.exception_date = ?", @easy_user_working_time_calendar.id, @day])
      exc.destroy if exc
    else
      exc = EasyUserTimeCalendarException.find(:first, :conditions => ["#{EasyUserTimeCalendarException.table_name}.calendar_id = ? AND #{EasyUserTimeCalendarException.table_name}.exception_date = ?", @easy_user_working_time_calendar.id, @day])
      exc ||= EasyUserTimeCalendarException.new(:calendar_id => @easy_user_working_time_calendar.id, :exception_date => @day)
      exc.working_hours = @working_hours
      exc.save
    end

    find_calendar && prepare_variables #reload

    render :action => 'inline_show'
  end

  def assign_to_user
    parent_calendar = EasyUserWorkingTimeCalendar.find(params[:working_time_calendar]) if params[:working_time_calendar]
    current_calendar = EasyUserWorkingTimeCalendar.find_by_user(@user)
    preserve_calendar_exceptions = params[:preserve_calendar_exceptions] == '1'

    if parent_calendar && parent_calendar != current_calendar
      parent_calendar.assign_to_user(@user, preserve_calendar_exceptions)
      flash[:notice] = l(:notice_successful_create)
    elsif !parent_calendar && current_calendar
      current_calendar.destroy
      flash[:notice] = l(:notice_successful_delete)
    end

    redirect_to params[:back_url]
  end

  def reset
    @easy_user_working_time_calendar.reset

    flash[:notice] = l(:notice_successful_update)
    redirect_to params[:back_url]
  end

  def mass_exceptions
    from = begin; params[:mass_exception][:from].to_date; rescue; end
    to = begin; params[:mass_exception][:to].to_date; rescue; end
    working_hours = params[:mass_exception][:working_hours].to_f
    day_period = params[:mass_exception][:day_period].to_i

    (redirect_to(params[:mass_exception][:back_url]) && return) unless from || to

    day = from

    while day <= to
      if day.cwday == day_period
        exc = EasyUserTimeCalendarException.find(:first, :conditions => {:calendar_id => @easy_user_working_time_calendar.id, :exception_date => day})
        exc ||= EasyUserTimeCalendarException.new(:calendar_id => @easy_user_working_time_calendar.id, :exception_date => day)
        exc.working_hours = working_hours
        exc.save
      end
      day += 1
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_to params[:mass_exception][:back_url]
  end

  private

  def find_calendar
    @easy_user_working_time_calendar = EasyUserWorkingTimeCalendar.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def prepare_variables
    unless params[:day].blank?
      @day = begin; params[:day].to_date; rescue; end
    end
    @working_hours = params[:working_hours].to_f if params[:working_hours]
    unless params[:start_date].blank?
      @start_date = begin; params[:start_date].to_date; rescue; end
    end
    @start_date ||= Date.today
    @easy_user_working_time_calendar.initialize_inner_calendar(@start_date)
  end

  def find_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

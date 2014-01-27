class EasyAttendancesController < ApplicationController

  before_filter :find_easy_attendance, :only => [:show, :edit, :update, :destroy, :departure]
  before_filter :authorize_global, :except => [:change_activity]
  before_filter :safe_dates, :only => [:create, :update, :change_activity]
  before_filter :enabled_this

  accept_api_auth :show, :create

  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper

  helper :easy_attendances
  include EasyAttendancesHelper

  include EasyUtils::DateUtils

  # POST => :create; GET => :list
  def index
    retrieve_query(EasyAttendanceQuery)
    if in_mobile_view? && (params[:tab].nil? || params[:tab] == 'calendar')

      params[:tab] = 'list'

    end
    if params[:tab] == 'list'
      @query.default_list_columns << 'user'

      sort_init(@query.sort_criteria_init)
      sort_update(@query.sortable_columns)

      respond_to do |format|
        format.html {
          limit = per_page_option
          @entity_count = @query.entity_count
          @entity_pages = Redmine::Pagination::Paginator.new @entity_count, limit, params['page']

          if request.xhr? && @entity_pages.last_page.to_i < params['page'].to_i
            render_404
            return false
          end

          @entities = @query.prepare_result({:order => sort_clause, :offset => @entity_pages.offset, :limit => limit} )
        }
        format.csv {send_data(export_to_csv(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:csv, @query))}
        format.pdf {send_data(export_to_pdf(@query.prepare_result({:order => sort_clause}), @query), :filename => get_export_filename(:pdf, @query))}
      end
    elsif params[:tab].nil? || params[:tab] == 'calendar'
      @query.display_filter_columns_on_index, @query.display_filter_group_by_on_index = false, false

      unless params[:start_date].blank?
        @start_date = begin; params[:start_date].to_date; rescue; end
      end

      if @start_date
        @query.filters.delete('departure')
        @query.filters['arrival'] = HashWithIndifferentAccess.new(:operator => 'date_period_2', :values => HashWithIndifferentAccess.new(:from => @start_date.beginning_of_month, :to => @start_date.end_of_month))
      end

      @query.export_formats = {}

      @entities = @query.entities(:order => :arrival)

      @start_date ||= @entities.last.arrival.localtime.to_date  if @entities.any?
      @start_date ||= User.current.today

      @calendar = EasyAttendances::Calendar.new(@start_date, current_language, :month)

      @query.group_by = nil
      if @query.valid?
        @calendar.events = @entities
      end
      respond_to do |format|
        format.html
      end
    else
      render :status => 406
    end
  end

  def report
    params[:tab] = 'report'

    @saved_params = params[:report] || {}
    @saved_params[:period_type] ||= '2'
    @saved_params[:from] ||= Date.today.beginning_of_month
    @saved_params[:to] ||= Date.today


    date_range = get_date_range(@saved_params[:period_type], @saved_params[:period], @saved_params[:from], @saved_params[:to])
    @from, @to = date_range[:from], date_range[:to]

    @activities = EasyAttendanceActivity.sorted

    @users_and_groups = []
    if User.current.allowed_to?(:view_easy_attendance_other_users, nil, :global => true)
      @assignable_users = User.active.non_system_flag.sorted
      @assignable_users_for_options = []
      if @assignable_users.include?(User.current)
        @assignable_users_for_options << ["<< #{l(:label_me)} >>".html_safe, User.current.id]
      end
      @assignable_users_for_options.concat(@assignable_users.collect{|m| [m.name, m.id]})
      @users_and_groups = [
        [l(:label_issue_assigned_to_users), @assignable_users_for_options],
        [l(:label_issue_assigned_to_groups), Group.active.non_system_flag.order(:lastname).collect{|m| [m.name, m.id]}],
      ]
    end

    if !@saved_params[:users].blank? && User.current.allowed_to?(:view_easy_attendance_other_users, nil, :global => true)
      @selected_user_ids = Array.new
      @saved_params[:users].each do |id|
        p = Principal.find_by_id(id)
        if p.is_a?(User)
          @selected_user_ids << p.id
        elsif p.is_a?(Group)
          @selected_user_ids.concat(p.users.pluck(:id))
        end
      end
      @selected_user_ids.uniq!
    end

    @reports = Array.new
    User.active.non_system_flag.sorted.where(:id => @selected_user_ids || User.current.id).each do |user|
      @reports << EasyAttendanceReport.new(user, @from, @to)
    end
  end

  def show
    respond_to do |format|
      format.html {render :nothing => true}
      format.api
    end
  end

  def new
    arrival = begin
      params[:arrival_at].to_time
    rescue
      Date.today.to_time
    end
    @easy_attendance = EasyAttendance.new(:user => User.current)
    @easy_attendance.arrival = @easy_attendance.morning(arrival)
    @easy_attendance.departure = @easy_attendance.evening(arrival)
    @easy_attendance.easy_attendance_activity = EasyAttendanceActivity.default
    @easy_attendance_activities = EasyAttendanceActivity.sorted.all

    respond_to do |format|
      format.js
      format.html
    end
  end

  def arrival
    params[:only_arrival] = true
    @easy_attendance = EasyAttendance.new(:user => User.current)
    @easy_attendance.arrival = Time.now
    @easy_attendance.easy_attendance_activity = EasyAttendanceActivity.default
    @easy_attendance_activities = EasyAttendanceActivity.where(:at_work => true).sorted

    respond_to do |format|
      format.js
    end
  end

  def departure
    if @easy_attendance.update_attributes(:departure => Time.now)
      flash[:notice] = l(:notice_easy_attendance_departured, :at => format_time(@easy_attendance.departure))
      redirect_back_or_default easy_attendances_path
    else
      @easy_attendance_activities = EasyAttendanceActivity.where(:at_work => true).sorted
      render 'edit'
    end
  end

  def create
    @easy_attendance.current_user_ip = current_user_ip
    ensure_easy_attendance_non_work_activity
    stash_for_delivery = @easy_attendance.dup
    if @easy_attendance.errors.blank? && @easy_attendance.save
      stash_for_delivery.after_create_send_mail
      respond_to do |format|
        format.html do
          flash[:notice] = l(:notice_successful_create)
          redirect_back_or_default({:controller => 'easy_attendances', :action => 'index'})
        end
        format.api {render :action => 'show'}
      end
    else
      @easy_attendance_activities = EasyAttendanceActivity.sorted.all
      respond_to do |format|
        format.html {render :action => 'new'}
        format.api {render_validation_errors(@easy_attendance)}
      end
    end
  end

  def edit
    @easy_attendance.arrival = Time.now if @easy_attendance.arrival.blank?
    @easy_attendance_activities = EasyAttendanceActivity.sorted.all
    if @easy_attendance.departure.blank?
      if @easy_attendance.arrival.nil?
        @easy_attendance.departure = Time.now
      else
        @easy_attendance.departure = Time::local(@easy_attendance.arrival.year, @easy_attendance.arrival.month, @easy_attendance.arrival.day, Time.now.hour, Time.now.min)
      end
    end
  end

  def update
    @easy_attendance.current_user_ip = current_user_ip
    ensure_easy_attendance_non_work_activity
    stash_for_delivery = @easy_attendance.dup
    if @easy_attendance.errors.blank? && @easy_attendance.save
      stash_for_delivery.after_update_send_mail
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_attendances', :action => 'index', :tab => params[:tab]})
    else
      @easy_attendance_activities = EasyAttendanceActivity.sorted.all
      render :action => 'edit'
    end
  end

  def bulk_update
    @easy_attendances = EasyAttendance.where(:id => params[:ids])
    @easy_attendance_activities = EasyAttendanceActivity.sorted.all
    attributes = parse_params_for_bulk_entity_attributes(params[:easy_attendance])
    errors = Array.new
    @easy_attendances.each do |easy_attendance|
      easy_attendance.safe_attributes = attributes
      unless easy_attendance.save
        errors << "##{easy_attendance.id} : #{easy_attendance.errors.full_messages.join(', ')}"
      end
    end
    if errors.blank?
      flash[:notice] = l(:notice_successful_update)
    else
      flash[:error] = (l(:error_bulk_update_save, :count => @easy_attendances.count - errors.size) + '<br />' + errors.join('<br />')).html_safe
    end

    redirect_back_or_default({:controller => 'easy_attendances', :action => 'index', :tab => 'list'})
  end

  def destroy
    @easy_attendance.destroy
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default({:controller => 'easy_attendances', :action => 'index', :tab => params[:tab]})
  end

  def bulk_destroy
    @easy_attendances = EasyAttendance.where(:id => params[:ids])
    @easy_attendances.destroy_all
    flash[:notice] = l(:notice_successful_delete)
    redirect_back_or_default({:controller => 'easy_attendances', :action => 'index', :tab => 'list'})
  end

  # RESTFUL END

  def change_activity
    @activity = @easy_attendance.easy_attendance_activity
    respond_to do |format|
      format.js
    end
  end

  def quick_save
    @easy_attendance.departure = Time.now
    @easy_attendance.current_user_ip = current_user_ip
    if @easy_attendance.save
      flash[:notice] = l(:notice_successful_update)
      redirect_back_or_default({:controller => 'easy_attendances', :action => 'index'})
    else
      render :action => 'edit'
    end
  end

  def new_notify_after_arrived
    @me = User.current
    @user = User.find(params[:user_id])
    @easy_attendance_notify_count = EasyAttendanceUserArrivalNotify.where(:user_id => @user.id, :notify_to_id => @me.id).count
  end

  def create_notify_after_arrived
    @me = User.current
    @user = User.find(params[:user_id])
    EasyAttendanceUserArrivalNotify.create(:user_id => @user.id, :notify_to_id => @me.id, :message => params[:notify_message])

    redirect_to @user, :notice => l(:notice_successful_create)
  end

  private

  def find_easy_attendance
    @easy_attendance = EasyAttendance.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def safe_dates
    @easy_attendance ||= EasyAttendance.new
    @easy_attendance.attributes = params[:easy_attendance]

    [:arrival, :departure, :range_start_time].each do |attribute|
      if params[attribute]
        begin
          if params[attribute][:date].blank?
            date = @easy_attendance.arrival || Date.today
          else
            date = params[attribute][:date].to_date
          end
        rescue
          date = @easy_attendance.arrival || Date.today
        end
        if params[attribute][:time].is_a?(Hash)
          time = [params[attribute][:time][:hour], params[attribute][:time][:minute]]
        elsif params[attribute][:time].present?
          params_time = params[attribute][:time]
          if params_time =~ /^\d\d[:]\d\d$/
            time = params_time.split(':')
          elsif params_time =~ /^\d{4}$/
            time = [params_time[0..1],params_time[2..3]]
          end
        end

        datetime = if time.nil?
          cycle(@easy_attendance.morning(date), @easy_attendance.evening(date))
        elsif @easy_attendance.user.time_zone
          Time.use_zone(@easy_attendance.user.time_zone) do
            Time.zone.local(date.year, date.month, date.day, time[0], time[1])
          end
        else
          Time.local(date.year, date.month, date.day, time[0], time[1])
        end

        @easy_attendance.send("#{attribute}=", datetime)
      end
    end
  end

  def enabled_this
    unless EasyAttendance.enabled?
      render_403
    end
  end

  def authorize_my_attendance
    return @easy_attendance.can_edit?
  end

  def ensure_easy_attendance_non_work_activity
    if @easy_attendance.range && @easy_attendance.easy_attendance_activity && !@easy_attendance.easy_attendance_activity.at_work? && @easy_attendance.user
      # user_working_time_calendar
      uwtc = @easy_attendance.user.current_working_time_calendar
      t = @easy_attendance.arrival
      if t.nil?
        return @easy_attendance.errors.add(:arrival, :blank)
      end
      @easy_attendance.arrival = Time.local(t.year, t.month, t.day, uwtc.time_from.hour, uwtc.time_from.min)
      t = @easy_attendance.departure
      if t.nil?
        return @easy_attendance.errors.add(:departure, :blank)
      end
      @easy_attendance.departure = Time.local(t.year, t.month, t.day, uwtc.time_to.hour, uwtc.time_to.min)
      # find first working_day
      while !@easy_attendance.user.current_working_time_calendar.working_day?(@easy_attendance.arrival.to_date)
        @easy_attendance.arrival += 1.day
      end

      case @easy_attendance.range
      when EasyAttendance::RANGE_FULL_DAY
        a = @easy_attendance.arrival + uwtc.working_hours(@easy_attendance.arrival.to_date).hours
        @easy_attendance.departure = Time.utc(t.year, t.month, t.day, a.hour, a.min)
      when EasyAttendance::RANGE_FORENOON,  EasyAttendance::RANGE_AFTERNOON
        # t = @easy_attendance.arrival
        # time = @easy_attendance.range_start_time.split(':')

        # @easy_attendance.arrival = Time.local_time(t.year, t.month, t.day, time[0], time[1])
        @easy_attendance.arrival = @easy_attendance.range_start_time
        @easy_attendance.departure = @easy_attendance.arrival + (uwtc.working_hours(@easy_attendance.arrival.to_date) / 2.0).hours
      # when EasyAttendance::RANGE_AFTERNOON
      #   t = @easy_attendance.arrival
      #   time = @easy_attendance.range_start_time.split(':')

      #   @easy_attendance.arrival = Time.local_time(t.year, t.month, t.day, time[0], time[1])
      #   @easy_attendance.departure = @easy_attendance.arrival + (uwtc.working_hours(@easy_attendance.arrival.to_date) / 2.0).hours
      else
        raise 'Invalid EasyAttendance RANGE !!!'
      end
    end
  end
end

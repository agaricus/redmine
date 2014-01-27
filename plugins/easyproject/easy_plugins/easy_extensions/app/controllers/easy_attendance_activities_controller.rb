class EasyAttendanceActivitiesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def show
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])
  end

  def new
    @easy_attendance_activity = EasyAttendanceActivity.new
  end

  def create
    @easy_attendance_activity = EasyAttendanceActivity.new(params[:easy_attendance_activity])

    if @easy_attendance_activity.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to :controller => 'enumerations', :action => 'index'
    else
      render :action => 'new'
    end
  end

  def edit
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])
  end

  def update
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])

    respond_to do |format|
      if @easy_attendance_activity.update_attributes(params[:easy_attendance_activity])

        format.html {flash[:notice] = l(:notice_successful_update); redirect_to :controller => 'enumerations', :action => 'index'}
        format.api {render_api_ok}
      else
        format.html {render :action => 'edit'}
        format.api  { render_validation_errors(@easy_attendance_activity) }
      end
    end

  end

  def destroy
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])

    respond_to do |format|
      if @easy_attendance_activity.easy_attendances.any?
        @confirm = true
        flash[:error] = l(:error_can_not_delete_activity, :scope => :easy_attendance)
        format.html {redirect_to easy_attendance_activity_move_issues_path(@easy_attendance_activity)}
        format.js {
          @easy_attendance_activities = EasyAttendanceActivity.where(["#{EasyAttendanceActivity.table_name}.id != ?", @easy_attendance_activity.id])
        }
      else
        @easy_attendance_activity.destroy

        format.js {}
        format.html {
          redirect_to :controller => 'enumerations', :notice => l(:notice_successful_delete)
        }
      end
    end
    #redirect_to :controller => 'enumerations'
  end

  def move_attendances
    @easy_attendance_activity = EasyAttendanceActivity.find(params[:id])
    @easy_attendance_activities = EasyAttendanceActivity.where(["#{EasyAttendanceActivity.table_name}.id != ?", @easy_attendance_activity.id])

    if request.post? && (params[:easy_attendance_activity_to].present? && params[:easy_attendance_activity_to].to_i != @easy_attendance_activity.id)
      @easy_attendance_activity_to = EasyAttendanceActivity.find(params[:easy_attendance_activity_to])
      @easy_attendance_activity.easy_attendances.update_all(:easy_attendance_activity_id => @easy_attendance_activity_to.id)
      @easy_attendance_activity.reload
      if @easy_attendance_activity.easy_attendances.any?
        flash[:error] = l(:error_can_not_delete_activity, :scope => :easy_attendance)
        redirect_to move_attendances_easy_attendance_activity_path(@easy_attendance_activity)
      else
        flash[:notice] = l(:notice_successful_delete)
        @easy_attendance_activity.destroy
        redirect_to :controller => 'enumerations'
      end
    end
  end

  def reload_time_entry_activities
    project = Project.find(params[:easy_attendance_activity][:mapped_project_id])

    render :partial => 'easy_attendance_activities/time_entry_activities', :locals => {:project => project, :selected => params[:easy_attendance_activity][:mapped_time_entry_activity_id]}
  end

end

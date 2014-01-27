class EasyRepeatingController < ApplicationController
  before_filter :require_login
  before_filter :find_entity

  def show_repeating_options
    @entity.easy_repeat_settings['period'] ||= 'daily'
    @entity.easy_repeat_settings['daily_option'] ||= 'each'
    @entity.easy_repeat_settings['yearly_option'] ||= 'date'
    @entity.easy_repeat_settings['endtype'] ||= 'endless'
    @entity.easy_is_repeating = true

    case Setting.start_of_week.to_i
    when 1
      @first_dow ||= (1 - 1)%7 + 1
    when 6
      @first_dow ||= (6 - 1)%7 + 1
    when 7
      @first_dow ||= (7 - 1)%7 + 1
    else
      @first_dow ||= (l(:general_first_day_of_week).to_i - 1)%7 + 1
    end

    @object_name = params[:object_name]
    @settings = @entity.easy_repeat_settings
    respond_to do |format|
      format.js
      format.html
    end
  end

  def disable_easy_repeating
    @entity.update_attributes({:easy_is_repeating => false, :easy_repeat_settings => {}})

    redirect_to @entity, :notice => l(:notice_successful_update)
  end

  private

  def find_entity
    @entity = params[:entity_type].constantize.find_or_initialize_by_id(params[:entity_id])
  end
end

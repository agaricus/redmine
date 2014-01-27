class EasyQuerySettingsController < ApplicationController
  layout 'admin'
  menu_item :easy_query_settings

  before_filter :require_admin

  helper :easy_query_settings
  include EasyQuerySettingsHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :entity_attribute
  include EntityAttributeHelper
  helper :easy_query
  include EasyQueryHelper
  helper :sort
  include SortHelper
  helper :attachments
  include AttachmentsHelper

  def index
    @easy_query = EasyQuery.registered_subclasses.keys.first.new
    default_group_by
  end

  def setting
    @easy_query = params[:tab].camelcase.constantize.new if params[:tab]
    @easy_query ||= EasyQuery.registered_subclasses.keys.first.new
    default_group_by
    render :action => 'index'
  end

  def save
    settings = (params[:easy_query] || {}).dup.symbolize_keys

    update_default_filters(params[:tab], params)
    update_default_list_columns(params[:tab], settings[:column_names])
    update_default_grouped_by(params[:tab], settings[:group_by])
    #update_default_sort(params[:tab], settings[:sort_criteria])

    redirect_to :action => 'setting', :tab => params[:tab]
  end

  private

  def default_group_by
    group_by = EasySetting.where(:name => "#{@easy_query.class.name.underscore}_grouped_by").first
    @easy_query.group_by = group_by.value unless group_by.nil?
  end

  def update_default_filters(easy_query, params)
    name = "#{easy_query}_default_filters"

    default_filters = Hash.new
    params[:fields].each do |field|
      default_filters[field] = {:operator => params[:operators][field], :values => params[:values][field]}
    end if params[:fields]

    update_easy_settings(name, default_filters)
  end

  def update_default_list_columns(easy_query, values)
    name = "#{easy_query}_list_default_columns"
    update_easy_settings(name, values)
  end

  def update_default_grouped_by(easy_query, values)
    name = "#{easy_query}_grouped_by"
    update_easy_settings(name, values)
  end

  def update_default_sort(easy_query, values)
    sort_array, sort_string_s, sort_string_l = Array.new, Array.new, Array.new
    values.each do |i, sort|
      if sort[0].present? && sort[1].present?
        sort_array << [sort[0], sort[1]]
        sort_string_s << "#{sort[0]}:#{sort[1]}"
      elsif sort[0].present?
        sort_array << sort[0]
        sort_string_s << "#{sort[0]}:asc"
      end

    end

    update_easy_settings("#{easy_query}_default_sorting_array", sort_array)
    update_easy_settings("#{easy_query}_default_sorting_string_short", sort_string_s.join(','))
    #update_easy_settings("#{easy_query}_default_sorting_string_long", sort_string_s.join(','))
  end

  def update_easy_settings(name, values)
    easy_setting = EasySetting.where(:name => name).first
    easy_setting ||= EasySetting.new(:name => name, :value => Array.new)
    easy_setting.value = values

    if !easy_setting.new_record? && values.blank?
      easy_setting.destroy
    else
      easy_setting.save
    end
  end

end
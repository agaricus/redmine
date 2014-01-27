module EasySettingHelper

  def save_easy_settings(project = nil)
    if params[:easy_setting] && params[:easy_setting].is_a?(Hash)
      settings = (params[:easy_setting] || {}).dup.symbolize_keys
      settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if{|v| v.blank? } if value.is_a?(Array)

        if project
          set = EasySetting.where(:name => name.to_s, :project_id => project.id).first
        else
          set = EasySetting.where(:name => name.to_s, :project_id => nil).first
        end

        if project && (set.nil? || !set.nil? && set.project_id.blank?)
          set = EasySetting.new(:name => name.to_s, :project_id => project.id)
        end

        set.value = case name.to_sym
        when *EasySetting.boolean_keys
          value.to_boolean
        when :attachment_description
          esa = EasySetting.where(:name => 'attachment_description_required', :project_id => nil).first
          case value
          when 'required'
            esa.update_attribute(:value, true)
            true
          when '1'
            esa.update_attribute(:value, false)
            true
          else
            esa.update_attribute(:value, false)
            false
          end
        else
          value
        end

        set.save
      end

      params.delete(:easy_setting)
    end
  end

end
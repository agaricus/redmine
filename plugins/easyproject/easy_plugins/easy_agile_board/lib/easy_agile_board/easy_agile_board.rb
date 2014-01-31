module EasyAgileBoard
  class << self

    def issue_status_id(relation_type)
      status_setting = Setting.plugin_easy_agile_board.try(:value_at, "#{relation_type}_status_id")
      if status_setting.present?
        status_setting.to_i
      else
        nil
      end
    end

  end
end

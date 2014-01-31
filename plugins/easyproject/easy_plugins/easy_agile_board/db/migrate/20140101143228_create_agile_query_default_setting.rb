class CreateAgileQueryDefaultSetting < ActiveRecord::Migration
  def up
    EasySetting.create(:name => 'easy_agile_board_query_default_filters', :value => {
      'status_id' => {:operator => 'o', :values => ['1']},
      'is_planned' => {:operator => '=', :values => ['0']}
    })
  end

  def down
    EasySetting.where(:name => 'easy_agile_board_query_default_filters').destroy_all
  end
end

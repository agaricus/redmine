class CreateYouTubePublishingModule < ActiveRecord::Migration
  def up
    EasyPublishingModule.create(:name => 'youtube')
  end

  def down
    EasyPublishingModule.where(:name => 'youtube').destroy_all
  end
end

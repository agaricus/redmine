class CreateEasyGlobalRatings < ActiveRecord::Migration
  def self.up
    create_table :easy_global_ratings, :force => true do |t|
      t.references :customized, :polymorphic => true
      t.float :value
    end
  end

  def self.down
    drop_table :easy_global_ratings
  end
end
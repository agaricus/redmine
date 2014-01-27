class CreateEasyPageAvailableModules < ActiveRecord::Migration

  def self.up
    create_table :easy_page_available_modules do |t|
      t.belongs_to :easy_pages, :easy_page_modules
    end
  end

  def self.down
    drop_table :easy_page_available_modules
  end
end
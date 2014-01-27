class CreateEasyPages < ActiveRecord::Migration

  def self.up
    create_table :easy_pages do |t|
      t.column :page_name, :string, { :null => false, :length => 255 }
      t.column :layout_path, :string, { :null => false, :length => 255 }
    end

    EasyPage.create :page_name => "my-page", :layout_path => "easy_page_layouts/two_column_header_first_wider"
    EasyPage.create :page_name => "project-overview", :layout_path => "easy_page_layouts/two_column_header_right_sidebar"
  end

  def self.down
    drop_table :easy_pages
  end
end
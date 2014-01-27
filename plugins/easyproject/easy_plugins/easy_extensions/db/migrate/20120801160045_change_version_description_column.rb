class ChangeVersionDescriptionColumn < ActiveRecord::Migration
  def up
    change_column :versions, :description, :text, {:default => nil}
  end

  def down
    change_column :versions, :description, :string, {:default => ''}
  end
end

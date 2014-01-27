class ChangeNotesInJournals < ActiveRecord::Migration
  def up
    adapter_name = Journal.connection_config[:adapter]
    case adapter_name.downcase
    when 'mysql', 'mysql2'
      change_column :journals, :notes, :text, {:limit => 4294967295}
    end
  end

  def down
  end
end

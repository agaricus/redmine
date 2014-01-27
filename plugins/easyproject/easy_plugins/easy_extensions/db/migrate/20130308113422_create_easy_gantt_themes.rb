class CreateEasyGanttThemes < ActiveRecord::Migration
  def up
    return if table_exists?(:easy_gantt_themes)

    create_table :easy_gantt_themes do |t|
      t.string :name

      t.integer :header_color_r
      t.integer :header_color_g
      t.integer :header_color_b

      t.integer :header_font_color_r
      t.integer :header_font_color_g
      t.integer :header_font_color_b
    end
  end

  def down
    drop_table :easy_gantt_themes
  end
end

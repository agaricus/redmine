class CreateEasyTranslations < ActiveRecord::Migration
  def up
    create_table :easy_translations do |t|
      t.references :entity, :polymorphic => true
      t.string :entity_column, :null => false
      t.string :lang, :null => false, :default => 'en'
      t.string :value

      t.timestamps
    end

    add_index(:easy_translations, [:entity_id, :entity_type,:entity_column, :lang], :unique => true, :name => 'easy_translations_entity_lang')
  end

  def down
    drop_table :easy_translations
  end
end

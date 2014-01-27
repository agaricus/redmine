class ChangeOrCreateActsAsTagagble < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.table_exists?(:taggings)
        add_column(:taggings, :tagger_id, :integer) unless column_exists?(:taggings, :tagger_id)
        add_column(:taggings, :tagger_type, :string) unless column_exists?(:taggings, :tagger_type)
        add_column(:taggings, :context, :string, :limit => 128) unless column_exists?(:taggings, :context)

      ActsAsTaggableOn::Tagging.where(:context => nil).update_all(:context => 'tags')
    else
      create_table :taggings do |t|
        t.column :tag_id, :integer
        t.column :taggable_id, :integer

        t.column :taggable_type, :string

        t.references :tagger, :polymorphic => true
        t.string :context, :limit => 128

        t.column :created_at, :datetime
      end

      add_index :taggings, :tag_id
      add_index :taggings, [:taggable_id, :taggable_type, :context]
    end

    unless ActiveRecord::Base.connection.table_exists?(:tags)
      create_table :tags do |t|
        t.column :name, :string
      end
    end

  end

  def down
    drop_table :taggings
    drop_table :tags
  end

end

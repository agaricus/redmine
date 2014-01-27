class EasyTextileMigrator < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true

  def self.all_entities
    {
      'Changeset' => [:comments],
      'Comment' => [:comments],
      'Document' => [:description],
      'Issue' => [:description],
      'Journal' => [:notes],
      'Message' => [:content],
      'News' => [:description],
      'Project' => [:description],
      'WikiContent' => [:comments, :text]
    }
  end

  def self.migrate_entity_column_to_html(entity, column, source_formatting)
    raise ArgumentError, 'Entity cannot be null!' if entity.nil?
    raise ArgumentError, 'Column cannot be null!' if column.nil?
    raise ArgumentError, 'Column is not from entity!' if !entity.respond_to?(column.to_sym)
    raise ArgumentError, 'Source formatting cannot be null!' if source_formatting.nil?

    return if EasyTextileMigrator.where(:entity_type => entity.class.name, :entity_id => entity.id, :entity_column => column.to_s, :source_formatting => source_formatting).exists?

    etm = EasyTextileMigrator.new(:entity => entity, :entity_column => column.to_s, :source_formatting => source_formatting)
    source_text = entity.send(column.to_sym)

    return if source_text.nil?

    target_text = Redmine::WikiFormatting.formatter_for(source_formatting).new(source_text.dup).to_html

    etm.source_text = source_text
    etm.target_text = target_text

    if etm.save
      begin
        entity.update_column(column.to_sym, target_text)
      rescue ActiveRecord::StaleObjectError
        entity.reload
        entity.update_column(column.to_sym, target_text)
      end
    end
  end

  def self.migrate_all_entities_to_html(source_formatting)
    EasyTextileMigrator.all_entities.each do |klass, columns|
      klass.constantize.all.each do |entity|
        columns.each do |column|
          EasyTextileMigrator.migrate_entity_column_to_html(entity, column, source_formatting)
        end
      end
    end

    setting = Setting.where(:name => 'welcome_text').first
    if setting
      EasyTextileMigrator.migrate_entity_column_to_html(setting, :value, source_formatting)
    end

    return true
  end
  
  def self.unmigrate_all_entities
    EasyTextileMigrator.all.each do |etm|
      etm.unmigrate_entity_column
    end
  end

  def unmigrate_entity_column
    return if self.entity.nil?
    begin
      if self.entity.update_attribute(self.entity_column.to_sym, self.source_text)
        self.destroy
      end
    rescue ActiveRecord::StaleObjectError
      self.entity.reload
      if self.entity.update_column(self.entity_column.to_sym, self.source_text)
        self.destroy
      end
    end
  end

end
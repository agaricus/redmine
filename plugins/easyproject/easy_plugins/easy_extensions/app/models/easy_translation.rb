class EasyTranslation < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true

  validates :value, :entity_column, :lang, :presence => true

  # Find translation for entity + column.
  # Search in user translation and EN for default
  def self.get_translation(entity, column, lang=nil)
    lang = lang.to_s
    translation_scoped = entity.easy_translations.where(:entity_column => column)

    if default_lang = entity.class.translater_options[:default_lang]
      t = EasyTranslation.arel_table
      translation_scoped = translation_scoped.where(t[:lang].eq(lang).or(t[:lang].eq(default_lang)))

      translation = translation_scoped.all.detect{|i| i.lang == lang}
    else
      translation_scoped = translation_scoped.where(:lang => lang)
    end

    translation ||= translation_scoped.first

    return translation
  end

  def self.set_translation(entity, column, value, lang=nil)
    lang ||= User.current.current_language
    if entity.is_a?(Hash)
      entity = entity[:entity_type].camelcase.constantize.find(entity[:entity_id])
    end

    translation = entity.easy_translations.where(:entity_column => column, :lang => lang).first
    translation ||= entity.easy_translations.build(:entity_column => column, :lang => lang)
    translation.value = value
    translation
  end

  def to_s
    self.value.to_s
  end
end

module EasyExtensions
  module EasyTranslator
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_easy_translate(options = {})
        return if self.included_modules.include?(EasyExtensions::EasyTranslator::InstanceMethods) || !EasyTranslation.table_exists?
        cattr_accessor :translater_options
        self.translater_options = {}
        # default column for translate
        columns = options.delete(:columns)
        translater_options[:columns] = columns.blank? ? [:name] : columns.map(&:to_sym)
        translater_options[:default_lang] = options[:default_translation_lang] # :en || :cs

        has_many :easy_translations, :as => :entity

        translater_options[:columns].each do |name|

          define_method(name) do |options={}|
            read_attribute(name, options)
          end
          alias_method :"#{name}_before_type_cast", name

          define_method :"easy_translated_#{name}" do |options={}|
            read_attribute(name, options)
          end

          define_method :"easy_translated_#{name}=" do |locales_value|
            locales_value.each do |locale, value|
              write_attribute(name, value, {:locale => locale})
            end
          end
        end

        send :include, EasyExtensions::EasyTranslator::InstanceMethods

        after_initialize {@cached_translations ||= HashWithIndifferentAccess.new}
        after_save :save_translations
      end
    end

    module InstanceMethods
      def self.included(base)
        base.extend ClassMethods
      end
      def read_attribute(attribute, options={})
        options = {:translated => true, :locale => User.current.current_language}.merge(options)
        if self.class.translater_options[:columns].include?(attribute.to_sym) && (options[:translated] && options[:locale])
          read_easy_translated_attribute(attribute, options[:locale]).try(:to_s) || super(attribute)
        else
          super(attribute)
        end
      end

      def write_attribute(attribute, value, options = {})
        options = {:locale => User.current.current_language}.merge(options)
        if !value.blank? && self.class.translater_options[:columns].include?(attribute.to_sym) && options[:locale] && !self.new_record?

          @translation_columns_to_save ||= Array.new
          translation_from_cache = @cached_translations[options[:locale]]

          if translation_from_cache
            translation_from_cache.value = value
            @translation_columns_to_save << translation_from_cache
          else
            @translation_columns_to_save << EasyTranslation.set_translation(self, attribute, value, options[:locale])
          end
        else
          super(attribute, value)
        end
      end

      private

      def read_easy_translated_attribute(attribute, lang=nil)
        lang ||= User.current.current_language
        @cached_translations[lang] ||= EasyTranslation.get_translation(self, attribute, lang)
        @cached_translations[lang]
      end

        # save translations after entity saved.
        # this is for rollback
      def save_translations
        @translation_columns_to_save && @translation_columns_to_save.map(&:'save!')
      end

      module ClassMethods
      end
    end
  end
end
ActiveRecord::Base.send(:include, EasyExtensions::EasyTranslator)

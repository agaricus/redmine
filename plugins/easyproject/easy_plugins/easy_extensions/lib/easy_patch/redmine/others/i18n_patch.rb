module EasyPatch
  module I18nPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :format_time, :easy_extensions
        alias_method_chain :valid_languages, :easy_extensions

        def format_short_date(date)
          return nil unless date
          d = date.is_a?(Date) ? date : begin; date.to_date; rescue; nil; end
          "#{d.day}.#{d.month}." if d
        end

        def format_date_or_time(value)
          if value.is_a?(Date)
            format_date(value)
          else
            format_time(value)
          end
        end

      end
    end

    module InstanceMethods

      def format_time_with_easy_extensions(time, include_date = true)
        return nil unless time
        options = {}
        options[:format] = (Setting.time_format.blank? ? :time : Setting.time_format)
        options[:locale] = User.current.language unless User.current.language.blank?
        begin
          time = time.to_time if time.is_a?(String)
          zone = User.current.time_zone
          local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
          (include_date ? "#{format_date(local)} " : "") + ::I18n.l(local, options)
        rescue
          time
        end
      end

      def valid_languages_with_easy_extensions
        EasyExtensions::SUPPORTED_LANGS
      end

    end
  end
end

module EasyPatch
  module I18nBackendImplementationPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :available_locales, :easy_extensions

      end
    end

    module InstanceMethods

      def available_locales_with_easy_extensions
        @available_locales ||= Dir.glob(File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'config', 'locales', '*.yml')).collect {|f| File.basename(f).split('.').first}.collect(&:to_sym)
      end

    end
  end
end

module EasyPatch
  module I18nBackendPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        include ::I18n::Backend::Pluralization

        def pluralizers
          @pluralizers = {
            :cs => lambda { |n| n == 1 ? :one : [2, 3, 4].include?(n) ? :few : :other },
            :da => lambda { |n| n == 1 ? :one : :other },
            :de => lambda { |n| n == 1 ? :one : :other },
            :en => lambda { |n| n == 1 ? :one : :other },
            :es => lambda { |n| n == 1 ? :one : :other },
            :fi => lambda { |n| n == 1 ? :one : :other },
            :fr => lambda { |n| n.between?(0, 2) && n != 2 ? :one : :other },
            :hu => lambda { |n| :other },
            :it => lambda { |n| n == 1 ? :one : :other },
            :ja => lambda { |n| :other },
            :pt => lambda { |n| [0, 1].include?(n) ? :one : :other },
            :"pt-BR" => lambda { |n| n == 1 ? :one : :other },
            :ru => lambda { |n| n % 10 == 1 && n % 100 != 11 ? :one : [2, 3, 4].include?(n % 10) && ![12, 13, 14].include?(n % 100) ? :few : n % 10 == 0 || [5, 6, 7, 8, 9].include?(n % 10) || [11, 12, 13, 14].include?(n % 100) ? :many : :other },
            :sv => lambda { |n| n == 1 ? :one : :other },
            :zh => lambda { |n| :other },
            :"zh-TW" => lambda { |n| :other }
          }
        end

      end
    end

    module InstanceMethods

    end
  end
end

EasyExtensions::PatchManager.register_other_patch 'Redmine::I18n', 'EasyPatch::I18nPatch'
EasyExtensions::PatchManager.register_other_patch 'Redmine::I18n::Backend::Implementation', 'EasyPatch::I18nBackendImplementationPatch'
# EasyExtensions::PatchManager.register_other_patch 'Redmine::I18n::Backend', 'EasyPatch::I18nBackendPatch'

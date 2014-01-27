module EasyExtensions
  module EasyLookups

    class EasyLookup
      include Redmine::I18n

      cattr_accessor :available
      @@available = {}

      def initialize
        raise NotImplementedError, 'You have to override attributes method.' if self.attributes.blank?
      end

      def attributes
        []
      end

      def translated_name
        l("easy_lookup.#{entity_name.underscore}.label")
      end

      def entity_name
        @entity_name ||= self.class.name[(self.class.name.rindex(':') + 1)..-1].gsub(/EasyLookup/, '')
      end

      # Array of custom fields types that are disallowed (e.g. [DocumentCustomField, VersionCustomField, ...]
      def except_for_type
        []
      end

      # Array of custom fields types that are allowed (e.g. [ProjectCustomField, IssueCustomField, ...]
      def only_for_type
        []
      end

      class << self

        def map(&block)
          yield self
        end

        def register(easy_lookup)
          raise ArgumentError, '' unless easy_lookup.is_a?(EasyExtensions::EasyLookups::EasyLookup)
          @@available[easy_lookup.entity_name] = easy_lookup
        end

        def available_lookups_by_type(type)
          @@available.values.select{|l| (l.except_for_type.blank? && l.only_for_type.blank?) || 
              (!l.except_for_type.blank? && !l.except_for_type.include?(type)) ||
              (!l.only_for_type.blank? && l.only_for_type.include?(type))}
        end

        def available_lookup_by_entity_name(entity_name)
          @@available[entity_name]
        end

      end

    end

  end
end
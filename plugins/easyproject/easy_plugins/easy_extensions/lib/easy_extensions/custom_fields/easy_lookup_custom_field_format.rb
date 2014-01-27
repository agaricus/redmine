module EasyExtensions
  module CustomFields

    class EasyLookupCustomFieldFormat < Redmine::CustomFieldFormat

      def initialize(options={})
        super('easy_lookup', options)
      end

      def self.entity_to_lookup_values(entity, options={})
        entities = Array(entity)
        lookup_values = {}
        options[:id] ||= :id
        options[:display_name] ||= :to_s

        entities.each do |e|
          if options[:id].is_a?(Symbol)
            id = e.send(options[:id])
          elsif options[:id].is_a?(Proc)
            id = options[:id].call(e)
          end
          if options[:display_name].is_a?(Symbol)
            display_name = e.send(options[:display_name])
          elsif options[:display_name].is_a?(Proc)
            display_name = options[:display_name].call(e)
          end

          lookup_values[id] = display_name.to_str if id && display_name
        end

        lookup_values
      end

      def self.entity_ids_to_lookup_values(entity_type, ids, options={})
        begin
          entity_class = entity_type.constantize
        rescue
          return {}
        end
        entities = entity_class.where( :id => ids ).all
        return {} if entities.blank?
        options[:display_name] ||= options[:attribute].to_s.sub('link_with_', '').to_sym if options[:attribute]
        entity_to_lookup_values( entities, options )
      end
    end


    def format_as_easy_lookup(value)
    end

    #just a legacy method TODO: delete!
    def values_are_different?(value1, value2)
      return value1 != value2
    end
  end

end

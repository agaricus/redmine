module EasyPatch
  module ActsAsSearchablePatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :search, :easy_extensions

      end
    end

    module InstanceMethods

      def search_with_easy_extensions(tokens, projects=nil, options={})
        if projects.is_a?(Array) && projects.empty?
          # no results
          return [[], 0]
        end

        # TODO: make user an argument
        user = User.current
        tokens = [] << tokens unless tokens.is_a?(Array)
        projects = [] << projects unless projects.nil? || projects.is_a?(Array)

        limit_options = {}
        limit_options[:limit] = options[:limit] if options[:limit]

        # Try assign columns to type of column
        if searchable_options[:column_types].blank?
          column_types = {:names => [], :descriptions => [], :comments => [], :others => []}
          searchable_options[:columns].each do |column|
            case column
            when /^name|#{table_name}\.name$/, /title|subject|firstname|lastname/
              column_types[:names] << column
            when /description|content|text/
              column_types[:descriptions] << column
            when /comment|notes/
              column_types[:comments] << column
            else
              column_types[:others] << column
            end
          end
        else
          column_types = searchable_options[:column_types]
          column_types[:names] ||= []
          column_types[:descriptions] ||= []
          column_types[:comments] ||= []
          column_types[:others] ||= []
        end

        columns = Array.new
        EasyExtensions.easy_searchable_column_types.each do |column|
          columns << column_types[column.pluralize.to_sym] if options[:use_columns].nil? || options[:use_columns].include?(column)
        end
        columns.flatten!

        token_clauses = columns.collect {|column| "(LOWER(#{column}) LIKE ?)"}

        if options[:use_columns] && options[:use_columns].include?('other')
          searchable_custom_fields = CustomField.where(:type => "#{self.name}CustomField", :searchable => true)
          searchable_custom_fields.each do |field|
            sql = "#{table_name}.id IN (SELECT customized_id FROM #{CustomValue.table_name}" +
              " WHERE customized_type='#{self.name}' AND customized_id=#{table_name}.id AND LOWER(value) LIKE ?" +
              " AND #{CustomValue.table_name}.custom_field_id = #{field.id})" +
              " AND #{field.visibility_by_project_condition(searchable_options[:project_key], user)}"
            token_clauses << sql
          end
        end

        return [[], 0] if token_clauses.blank?
        sql = (['(' + token_clauses.join(' OR ') + ')'] * tokens.size).join(options[:all_words] ? ' AND ' : ' OR ')

        tokens_conditions = [sql, * (tokens.collect {|w| "%#{w.downcase}%"} * token_clauses.size).sort]

        scope = self.scoped
        project_conditions = []
        if searchable_options.has_key?(:permission)
          project_conditions << Project.allowed_to_condition(user, searchable_options[:permission] || :view_project)
        elsif respond_to?(:visible)
          scope = scope.visible(user)
        else
          ActiveSupport::Deprecation.warn "acts_as_searchable with implicit :permission option is deprecated. Add a visible scope to the #{self.name} model or use explicit :permission option."
          project_conditions << Project.allowed_to_condition(user, "view_#{self.name.underscore.pluralize}".to_sym)
        end
        # TODO: use visible scope options instead
        project_conditions << "#{searchable_options[:project_key]} IN (#{projects.collect(&:id).join(',')})" unless projects.nil?

        results = []
        results_count = 0

        additional_conditions = []
        if !searchable_options[:additional_conditions].nil?
          if searchable_options[:additional_conditions].is_a?(String)
            additional_conditions << searchable_options[:additional_conditions]
          elsif searchable_options[:additional_conditions].is_a?(Array)
            additional_conditions.concat(searchable_options[:additional_conditions])
          elsif searchable_options[:additional_conditions].is_a?(Proc)
            additional_conditions << searchable_options[:additional_conditions].call
          end
        end

        scope = scope.
          includes(searchable_options[:include]).
          order("#{searchable_options[:order_column]} " + (options[:before] ? 'DESC' : 'ASC')).
          where(project_conditions).
          where(tokens_conditions).
          where(additional_conditions)

        results_count = scope.count

        scope_with_limit = scope.limit(options[:limit])
        if options[:offset]
          scope_with_limit = scope_with_limit.where("#{searchable_options[:date_column]} #{options[:before] ? '<' : '>'} ?", options[:offset])
        end
        results = scope_with_limit.all

        [results, results_count]
      end

    end

  end
end
EasyExtensions::PatchManager.register_redmine_plugin_patch 'Redmine::Acts::Searchable::InstanceMethods::ClassMethods', 'EasyPatch::ActsAsSearchablePatch'

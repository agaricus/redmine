module EasyPatch
  module SearchControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :index, :easy_extensions
      end
    end

    module InstanceMethods
      def index_with_easy_extensions
        @question = params[:q] || ""
        @question.strip!
        @all_words = params[:all_words] ? params[:all_words].present? : true
        @titles_only = params[:titles_only] ? params[:titles_only].present? : false
        @easy_searchable_column_types = params[:easy_searchable_column_type] || EasyExtensions.easy_searchable_column_types

        @scope_select = params[:scope] =~ /\d+/ || (params[:scope_type].nil? && @project) ? 'project' : params[:scope_type]
        projects_to_search =
          case params[:scope_type]
        when 'all'
          nil
        when 'my_projects'
          User.current.memberships.collect(&:project)
        when 'subprojects'
          @project ? (@project.self_and_descendants.active.all) : nil
        else
          projects = Project.where(:id => params[:scope])
          projects.any? ? projects.all : @project
        end

        if projects_to_search.respond_to?(:count) && projects_to_search.count == 1
          projects_to_search = projects_to_search.first
        end

        offset = nil
        begin; offset = params[:offset].to_time if params[:offset]; rescue; end

        # quick jump to an issue
        if EasySetting.value('quick_jump_to_an_issue')
          if (m = @question.match(/^#?(\d+)$/)) && (issue = Issue.visible.find_by_id(m[1].to_i))
            redirect_to issue_path(issue)
            return
          end
        end

        @object_types = Redmine::Search.available_search_types.dup - EasyExtensions::EasyProjectSettings.disabled_features[:search_types]
        if projects_to_search.is_a?(Project)
          # only show what the user is allowed to view
          @object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, projects_to_search)}
        end

        if @object_types.delete('issues')
          @object_types << 'issue_open'
          @object_types << 'issue_close'
        end

        @scope = @object_types.select {|t| params[t]}

        if params['issues']
          @scope << 'issue_open'
        end

        @scope = @object_types - ['issue_close'] if @scope.empty?

        # extract tokens from the question
        # eg. hello "bye bye" => ["hello", "bye bye"]
        @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
        # tokens must be at least 2 characters long
        @tokens = @tokens.uniq.select {|w| w.length > 1 }

        if !@tokens.empty?
          # no more than 5 tokens to search for
          @tokens.slice! 5..-1 if @tokens.size > 5

          @results = []
          @results_by_type = Hash.new {|h,k| h[k] = 0}

          limit = 10
          @scope.each do |s|
            r, c = s.singularize.camelcase.constantize.search(@tokens, projects_to_search,
              :all_words => @all_words,
              :titles_only => @titles_only,
              :limit => (limit+1),
              :offset => offset,
              :before => params[:previous].nil?,
              :use_columns => @easy_searchable_column_types)
            @results += r
            @results_by_type[s] += c
          end
          @results = @results.sort {|a,b| b.event_datetime <=> a.event_datetime}
          if params[:previous].nil?
            @pagination_previous_date = @results[0].event_datetime if offset && @results[0]
            if @results.size > limit
              @pagination_next_date = @results[limit-1].event_datetime
              @results = @results[0, limit]
            end
          else
            @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]
            if @results.size > limit
              @pagination_previous_date = @results[-(limit)].event_datetime
              @results = @results[-(limit), limit]
            end
          end
        else
          @question = ""
        end
        render :layout => false if request.xhr?
      end
    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'SearchController', 'EasyPatch::SearchControllerPatch'

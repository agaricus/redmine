module EasyPatch
  module JournalsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        helper :easy_query
        include EasyQueryHelper

        cache_sweeper :journal_sweeper, :only => [:edit]

        alias_method_chain :find_journal, :easy_extensions
        alias_method_chain :edit, :easy_extensions
        alias_method_chain :index, :easy_extensions
        alias_method_chain :new, :easy_extensions

        def public_journal
          @journal = Journal.visible.find(params[:id])
          if @journal.user_id == User.current.id || User.current.admin?
            @journal.update_attributes(:private_notes => false)
            flash[:notice] = l(:notice_journal_published)
            redirect_to @journal.journalized
          else
            render_403
          end
        end

      end
    end

    module InstanceMethods

      def find_journal_with_easy_extensions
        @journal = Journal.find(params[:id]) # original s visible je primo svazan s issue
        @project = @journal.journalized.project
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def index_with_easy_extensions
        retrieve_query(EasyIssueQuery)
        sort_init 'id', 'desc'
        sort_update(@query.sortable_columns)

        if @query.valid?
          @journals = @query.journals(:order => "#{Journal.table_name}.created_on DESC",
            :limit => 25)
        end
        @title = (@project ? @project.name : Setting.app_title) + ": " + (@query.new_record? ? l(:label_changes_details) : @query.name)
        render :layout => false, :content_type => 'application/atom+xml'
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def new_with_easy_extensions
        @journal = Journal.visible.find(params[:journal_id]) if params[:journal_id]
        if @journal
          user = @journal.user
          text = @journal.notes
        else
          user = @issue.author
          text = @issue.description
        end
        # Replaces pre blocks with [...]
        text = text.to_s.strip.gsub(%r{<pre>((.|\s)*?)</pre>}m, '[...]')
        @content = "#{ll(Setting.default_language, :text_user_wrote, user)}\n> "
        # If CKEDITOR else redmine default
        if Setting.text_formatting == 'HTML'
          @content << content_tag(:blockquote, text.html_safe) + "\n\n"
        else
          @content << text.gsub(/(\r?\n|\r\n?)/, "\n> ") + "\n\n"
        end
      rescue ActiveRecord::RecordNotFound
        render_404
      end

      def edit_with_easy_extensions
        (render_403; return false) unless @journal.editable_by?(User.current)
        if request.post?
          @journal.update_attributes(:notes => params[:notes]) if params[:notes]
          @journal.destroy if @journal.details.empty? && @journal.notes.blank?
          call_hook(:controller_journals_edit_post, { :journal => @journal, :params => params})
          respond_to do |format|
            format.html { redirect_back_or_default({:controller => @journal.journalized.class.name.underscore.pluralize, :action => 'show', :id => @journal.journalized}) }
            format.js { render :action => 'update' }
          end
        else
          respond_to do |format|
            format.html {
              # TODO: implement non-JS journal update
              render :nothing => true
            }
            format.js
          end
        end
      end

    end

  end

end
EasyExtensions::PatchManager.register_controller_patch 'JournalsController', 'EasyPatch::JournalsControllerPatch'

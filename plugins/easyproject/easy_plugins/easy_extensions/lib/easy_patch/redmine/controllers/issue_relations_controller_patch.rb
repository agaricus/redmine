module EasyPatch
  module IssueRelationsControllerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        skip_before_filter :find_issue, :find_project_from_association, :authorize, :find_relation

        before_filter :find_issue, :find_project_from_association, :authorize, :only => [:index, :create, :put_between]
        before_filter :find_relation, :except => [:index, :create, :put_between]

        helper :issues
        include IssuesHelper

        alias_method_chain :create, :easy_extensions

      end
    end

    module InstanceMethods

      def put_between
        issues = []
        if params[:relation_between]
          if !params[:relation_between][:issue_ids].blank?
            params[:relation_between][:issue_ids].each do |id|
              issue = Issue.find(id)
              issues << issue unless issue.blank?
            end
          end
        end
        if issues.length != 2
          flash[:error] = l(:error_put_between_issue_count)
        else
          issues.reverse! if issues[0].due_date && issues[1].due_date && issues[1].due_date < issues[0].due_date
          rel1, rel2 = IssueRelation.put_between(@issue, issues[0], issues[1])
          errors = []
          rel1.errors.full_messages.each{|m| errors << m.to_s} if rel1.errors.any?
          rel2.errors.full_messages.each{|m| errors << m.to_s} if rel2.errors.any?
          flash[:error] = errors.join('<br/>').html_safe if errors.any?
        end
        redirect_to :controller => 'issues', :action => 'show', :id => @issue
      end

      def create_with_easy_extensions
        @relation = @issue.relations_from.build(params[:relation])
        unsaved_relations = []
        if params[:relation]
          if values = params[:relation][:issue_to_id]
            Array(values).each do |issue_id|
              new_relation = @relation.dup
              new_relation.issue_to_id = issue_id

              unsaved_relations << new_relation unless new_relation.save
            end
          else
            unsaved_relations << @relation unless @relation.save
          end
        end

        respond_to do |format|
          format.html do
            if unsaved_relations.any?
              flash[:error] = unsaved_relations.collect{|relation|
                relation.errors.full_messages.join('<br/>') +
                  relation.issue_from.errors.full_messages.collect{|m| view_context.link_to_issue(relation.issue_from) + ': ' + m}.join('<br/>') +
                  relation.issue_to.errors.full_messages.collect{|m| view_context.link_to_issue(relation.issue_to) + ': ' + m}.join('<br/>')
              }.join('<br/>').html_safe
            else
              flash[:notice] = l(:notice_successful_update)
            end
            redirect_to redirect_to issue_path(@issue)
          end
          format.js {
            @relations = @issue.reload.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
          }
          format.api {
            if unsaved_relations.empty?
              render :text => '', :status => :created
            else
              render_validation_errors(unsaved_relations.first)
            end
          }
        end

      end

    end
  end

end
EasyExtensions::PatchManager.register_controller_patch 'IssueRelationsController', 'EasyPatch::IssueRelationsControllerPatch'

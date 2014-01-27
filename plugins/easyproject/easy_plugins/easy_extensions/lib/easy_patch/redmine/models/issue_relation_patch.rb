module EasyPatch
  module IssueRelationPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      base.class_eval do

        const_set(:EASY_TYPES,
          {
            IssueRelation::TYPE_PRECEDES =>    { :name => :label_preceding, :sym_name => :label_following,
                                  :order => 6, :sym => IssueRelation::TYPE_FOLLOWS },
            IssueRelation::TYPE_FOLLOWS =>     { :name => :label_following, :sym_name => :label_preceding,
                                  :order => 7, :sym => IssueRelation::TYPE_PRECEDES, :reverse => IssueRelation::TYPE_PRECEDES }
          }
        )

        before_save :check_if_record_is_uniq

        alias_method_chain :successor_soonest_start, :easy_extensions
        alias_method_chain :validate_issue_relation, :easy_extensions
        alias_method_chain :label_for,               :easy_extensions

        define_method(:'<=>_with_easy_extensions') do |relation|
          r = IssueRelation::TYPES[self.relation_type][:order] <=> IssueRelation::TYPES[relation.relation_type][:order]
          if r == 0
            if self.id.nil?
              1
            elsif relation.nil? || relation.id.nil?
              -1
            else
              self.id <=> relation.id
            end
          else
            r
          end
        end
        alias_method_chain :<=>, :easy_extensions

        private

        def check_if_record_is_uniq
          if IssueRelation.where(:issue_from_id => self.issue_from_id, :issue_to_id => self.issue_to_id).exists?
            return false
          else
            return true
          end
        end

      end
    end

    module InstanceMethods

      def successor_soonest_start_with_easy_extensions
        if (IssueRelation::TYPE_PRECEDES == self.relation_type) && delay && issue_from && (issue_from.start_date || issue_from.due_date)
          (issue_from.due_date || issue_from.start_date) + delay
        end
      end

      def validate_issue_relation_with_easy_extensions
        return if issue_from.nil? || issue_to.nil?
        if issue_from.new_record? || issue_to.new_record?
          errors.add :issue_to_id, :not_same_project unless issue_from.project_id == issue_to.project_id || Setting.cross_project_issue_relations?
        else
          validate_issue_relation_without_easy_extensions
        end
      end

      def label_for_with_easy_extensions(issue)
        if IssueRelation::EASY_TYPES[relation_type]
          IssueRelation::EASY_TYPES[relation_type][(self.issue_from_id == issue.id) ? :name : :sym_name]
        else
          label_for_without_easy_extensions(issue)
        end
      end

    end

    module ClassMethods

      def put_between(issue, issue_from, issue_to)
        existing_rel = IssueRelation.find(:first, :conditions => {:relation_type => IssueRelation::TYPE_PRECEDES, :issue_from_id => issue_from.id, :issue_to_id => issue_to.id})
        existing_rel.destroy unless existing_rel.blank?

        rel1 = IssueRelation.find(:first, :conditions => {:relation_type => IssueRelation::TYPE_PRECEDES, :issue_from_id => issue_from.id, :issue_to_id => issue.id})
        if rel1.blank?
          rel1 = IssueRelation.new(:relation_type => IssueRelation::TYPE_PRECEDES, :issue_from => issue_from, :issue_to => issue)
          rel1.save
        end

        rel2 = IssueRelation.find(:first, :conditions => {:relation_type => IssueRelation::TYPE_PRECEDES, :issue_from_id => issue.id, :issue_to_id => issue_to.id})
        if rel2.blank?
          rel2 = IssueRelation.new(:relation_type => IssueRelation::TYPE_PRECEDES, :issue_from => issue, :issue_to => issue_to)
          rel2.save
        end
        [rel1, rel2]
      end
    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'IssueRelation', 'EasyPatch::IssueRelationPatch'

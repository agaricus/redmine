module EasyAgileBoard
  module ProjectPatch

    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do

        has_many :easy_sprints, :order => 'due_date DESC'
        has_many :issue_easy_sprint_relations, :through => :easy_sprints

      end
    end

    module InstanceMethods
    end

    module ClassMethods
    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Project', 'EasyAgileBoard::ProjectPatch'

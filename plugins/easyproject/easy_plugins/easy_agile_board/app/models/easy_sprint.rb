class EasySprint < ActiveRecord::Base
  include Redmine::SafeAttributes

  belongs_to :project
  has_many :issue_easy_sprint_relations, :dependent => :destroy
  has_many :issues, :through => :issue_easy_sprint_relations

  validates_presence_of :name, :start_date, :due_date, :project

  after_initialize :set_defaults

  safe_attributes :name, :start_date, :due_date

  def assign_issue(issue, relation_type)
    if assignment = IssueEasySprintRelation.where(:issue_id => issue).first
      assignment.easy_sprint = self
    else
      assignment = issue_easy_sprint_relations.build(:issue => issue)
    end
    assignment.relation_type = relation_type
    assignment.save
    assignment
  end

  private

  def set_defaults
    if new_record?
      self.start_date = Date.today
      self.due_date = Date.today + 1.week
    end
  end

end

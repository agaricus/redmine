require 'easy_agile_board/easy_agile_board'
class IssueEasySprintRelation < ActiveRecord::Base
  belongs_to :issue
  belongs_to :easy_sprint

  TYPE_BACKLOG     = :backlog
  TYPE_NEW         = :new
  TYPE_REALIZATION = :realization
  TYPE_TO_CHECK    = :to_check
  TYPE_DONE        = :done

  TYPES = ActiveSupport::OrderedHash[{
    TYPE_BACKLOG      => 1,
    TYPE_NEW          => 2,
    TYPE_REALIZATION  => 3,
    TYPE_TO_CHECK     => 4,
    TYPE_DONE         => 5
  }].freeze

  validates :issue, :easy_sprint, :relation_type, :presence => true
  validates :relation_type, :inclusion => {:in => TYPES.values}

  after_save :update_issue

  def relation_type=(new_type)
    if new_type.is_a?(Numeric)
      super new_type
    elsif new_type.present?
      super TYPES[new_type.to_sym]
    else
      super nil
    end
  end

  def update_issue
    if issue_status_id = EasyAgileBoard.issue_status_id(TYPES.invert[relation_type])
      if issue.status_id != issue_status_id
        issue.init_journal(User.current)
        issue.status_id = issue_status_id
        issue.save
      end
    end
  end

end

class EasyUserAllocationWorkingPlanItem < ActiveRecord::Base

  cattr_accessor :is_enabled

  belongs_to :issue
  belongs_to :user

  validates :d_year, :d_week, :presence => true

  scope :in_date, lambda {|date| where(:d_year => date.year, :d_week => date.cweek)}

  def start_date
   Date.commercial(self.d_year, self.d_week, 1)
 end

 def end_date
   Date.commercial(self.d_year, self.d_week, 7)
 end

 def date=(date)
   self.d_year = date.year
   self.d_week = date.cweek
 end

 def allocations
  #EasyUserAllocation.allocations_for_issue(self.issue, self.user)
  self.user.easy_user_allocations.where(:date => self.start_date..self.end_date, :issue_id => self.issue_id)
 end

end

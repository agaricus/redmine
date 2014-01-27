class EasyProjectRelation < ActiveRecord::Base

  belongs_to :project_from, :class_name => 'Project', :foreign_key => 'project_from_id'
  belongs_to :project_to, :class_name => 'Project', :foreign_key => 'project_to_id'

  TYPE_PRECEDES     = "precedes"
  TYPE_FOLLOWS      = "follows"

  TYPES = { TYPE_PRECEDES =>    { :name => :label_precedes, :sym_name => :label_follows, :order => 1, :sym => TYPE_FOLLOWS },
    TYPE_FOLLOWS =>     { :name => :label_follows, :sym_name => :label_precedes, :order => 2, :sym => TYPE_PRECEDES, :reverse => TYPE_PRECEDES }
  }.freeze

  validates_presence_of :project_from, :project_to, :relation_type
  validates_inclusion_of :relation_type, :in => TYPES.keys
  validates_numericality_of :delay, :allow_nil => true
  validates_uniqueness_of :project_to_id, :scope => :project_from_id

  validate :validate_project_relation

  attr_protected :project_from_id, :project_to_id

  before_save :handle_project_order

  def visible?(user=User.current)
    (project_from.nil? || project_from.visible?(user)) && (project_to.nil? || project_to.visible?(user))
  end

  def deletable?(user=User.current)
    visible?(user) &&
      ((project_from.nil? || user.allowed_to?(:manage_easy_project_relations, project_from)) ||
        (project_to.nil? || user.allowed_to?(:manage_easy_project_relations, project_to)))
  end

  def after_initialize
    if new_record?
      if relation_type.blank?
        self.relation_type = EasyProjectRelation::TYPE_PRECEDES
      end
    end
  end

  def validate_project_relation
    case self.relation_type
    when EasyProjectRelation::TYPE_PRECEDES
      if EasyProjectRelation.find(:all, :conditions => {:relation_type => EasyProjectRelation::TYPE_PRECEDES, :project_to_id => project_to_id}).any?
        errors.add :base, l(:project_predecessor_error, :project_name => "\"#{self.project_to.name}\"")
      end
    when EasyProjectRelation::TYPE_FOLLOWS
      if EasyProjectRelation.find(:all, :conditions => {:relation_type => EasyProjectRelation::TYPE_PRECEDES, :project_to_id => project_from_id}).any?
        errors.add :base, l(:project_predecessor_error, :project_name => "\"#{self.project_from.name}\"")
      end
    end

    if project_from && project_to
      errors.add :project_to_id, :invalid if project_from_id == project_to_id
      #detect circular dependencies depending wether the relation should be reversed
      if TYPES.has_key?(relation_type) && TYPES[relation_type][:reverse]
        errors.add :base, :circular_dependency if project_from.all_dependent_project.include? project_to
      else
        errors.add :base, :circular_dependency if project_to.all_dependent_project.include? project_from
      end
    end
  end

  def other_project(project)
    (self.project_from_id == project.id) ? project_to : project_from
  end

  # Returns the relation type for +project+
  def relation_type_for(project)
    if TYPES[relation_type]
      if self.project_from_id == project.id
        relation_type
      else
        TYPES[relation_type][:sym]
      end
    end
  end

  def label_for(project)
    TYPES[relation_type] ? TYPES[relation_type][(self.project_from_id == project.id) ? :name : :sym_name] : :unknow
  end

  def handle_project_order
    reverse_if_needed

    if TYPE_PRECEDES == relation_type
      self.delay ||= 0
    else
      self.delay = nil
    end
    set_project_to_dates
  end

  def set_project_to_dates
    soonest_start = self.successor_soonest_start
    if soonest_start && project_to
      project_to.reschedule_after(soonest_start)
    end
  end

  def successor_soonest_start
    if (TYPE_PRECEDES == self.relation_type) && delay && project_from && (project_from.start_date || project_from.due_date)
      (project_from.due_date || project_from.start_date) + delay
    end
  end

  def <=>(relation)
    TYPES[self.relation_type][:order] <=> TYPES[relation.relation_type][:order]
  end

  def gerund_label_for(project)
    original_label = label_for(project)
    case original_label
    when :label_precedes
      :label_following
    when :label_follows
      :label_preceding
    else
      original_label
    end
  end

  private

  # Reverses the relation if needed so that it gets stored in the proper way
  # Should not be reversed before validation so that it can be displayed back
  # as entered on new relation form
  def reverse_if_needed
    if TYPES.has_key?(relation_type) && TYPES[relation_type][:reverse]
      project_tmp = project_to
      self.project_to = project_from
      self.project_from = project_tmp
      self.relation_type = TYPES[relation_type][:reverse]
    end
  end

end
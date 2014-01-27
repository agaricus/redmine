class EasyVersionRelation < ActiveRecord::Base

  belongs_to :version_from, :class_name => 'Version', :foreign_key => 'version_from_id'
  belongs_to :version_to, :class_name => 'Version', :foreign_key => 'version_to_id'

  TYPE_PRECEDES     = "precedes"
  TYPE_FOLLOWS      = "follows"

  TYPES = { TYPE_PRECEDES =>    { :name => :label_precedes, :sym_name => :label_follows, :order => 1, :sym => TYPE_FOLLOWS },
    TYPE_FOLLOWS =>     { :name => :label_follows, :sym_name => :label_precedes, :order => 2, :sym => TYPE_PRECEDES, :reverse => TYPE_PRECEDES }
  }.freeze

  validates_presence_of :version_from, :version_to, :relation_type
  validates_inclusion_of :relation_type, :in => TYPES.keys
  validates_numericality_of :delay, :allow_nil => true
  validates_uniqueness_of :version_to_id, :scope => :version_from_id

  validate :validate_version_relation

  attr_protected :version_from_id, :version_to_id

  before_save :handle_version_order

  def visible?(user=User.current)
    (version_from.nil? || version_from.visible?(user)) && (version_to.nil? || version_to.visible?(user))
  end

  def deletable?(user=User.current)
    visible?(user) &&
      ((version_from.nil? || user.allowed_to?(:manage_easy_version_relations, version_from.project)) ||
        (version_to.nil? || user.allowed_to?(:manage_easy_version_relations, version_to.project)))
  end

  def after_initialize
    if new_record?
      if relation_type.blank?
        self.relation_type = EasyVersionRelation::TYPE_PRECEDES
      end
    end
  end

  def validate_version_relation
    case self.relation_type
    when EasyVersionRelation::TYPE_PRECEDES
      if EasyVersionRelation.find(:all, :conditions => {:relation_type => EasyVersionRelation::TYPE_PRECEDES, :version_to_id => version_to_id}).any?
        errors.add :base, l(:version_predecessor_error, :version_name => "\"#{self.version_to.name}\"")
      end
    when EasyVersionRelation::TYPE_FOLLOWS
      if EasyVersionRelation.find(:all, :conditions => {:relation_type => EasyVersionRelation::TYPE_PRECEDES, :version_to_id => version_from_id}).any?
        errors.add :base, l(:version_predecessor_error, :version_name => "\"#{self.version_from.name}\"")
      end
    end

    if version_from && version_to
      errors.add :version_to_id, :invalid if version_from_id == version_to_id
      #detect circular dependencies depending wether the relation should be reversed
      if TYPES.has_key?(relation_type) && TYPES[relation_type][:reverse]
        errors.add :base, :circular_dependency if version_from.all_dependent_version.include? version_to
      else
        errors.add :base, :circular_dependency if version_to.all_dependent_version.include? version_from
      end
    end
  end

  def other_version(version)
    (self.version_from_id == version.id) ? version_to : version_from
  end

  # Returns the relation type for +version+
  def relation_type_for(version)
    if TYPES[relation_type]
      if self.version_from_id == version.id
        relation_type
      else
        TYPES[relation_type][:sym]
      end
    end
  end

  def label_for(version)
    TYPES[relation_type] ? TYPES[relation_type][(self.version_from_id == version.id) ? :name : :sym_name] : :unknow
  end

  def handle_version_order
    reverse_if_needed

    if TYPE_PRECEDES == relation_type
      self.delay ||= 0
    else
      self.delay = nil
    end
    set_version_to_dates
  end

  def set_version_to_dates
    soonest_start = self.successor_soonest_start
    if soonest_start && version_to
      version_to.reschedule_after(soonest_start)
    end
  end

  def successor_soonest_start
    if (TYPE_PRECEDES == self.relation_type) && delay && version_from && version_from.effective_date
      version_from.effective_date + delay
    end
  end

  def <=>(relation)
    TYPES[self.relation_type][:order] <=> TYPES[relation.relation_type][:order]
  end

  def gerund_label_for(version)
    original_label = label_for(version)
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
      version_tmp = version_to
      self.version_to = version_from
      self.version_from = version_tmp
      self.relation_type = TYPES[relation_type][:reverse]
    end
  end

end
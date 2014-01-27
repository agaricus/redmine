module EasyMoney
  module EasyMoneyBaseModel

    def self.included(base)
      base.class_eval do

        include Redmine::SafeAttributes

        belongs_to :entity, :polymorphic => true
        has_many :easy_external_synchronisations, :as => :entity, :dependent => :destroy

        acts_as_customizable
        acts_as_attachable

        validates :entity_type, :presence => true
        validates :entity_id, :presence => true
        validates_length_of :name, :in => 1..255, :allow_nil => false
        validates_numericality_of :price1, :allow_nil => true
        validates_numericality_of :price2, :allow_nil => true
        validates_numericality_of :vat, :allow_nil => true

        safe_attributes 'spent_on', 'name', 'description', 'price1', 'price2', 'vat', 'version_id'
        safe_attributes 'entity_type', 'entity_id', 'custom_field_values'

        def price1
          super || 0.0
        end

        def price2
          super || 0.0
        end

        def spent_on=(date)
          super
          if spent_on.is_a?(Time)
            self.spent_on = spent_on.to_date
          end

          return unless self.class.column_names.include?('tyear')

          self.tyear = spent_on ? spent_on.year : nil
          self.tmonth = spent_on ? spent_on.month : nil
          self.tweek = spent_on ? Date.civil(spent_on.year, spent_on.month, spent_on.day).cweek : nil
          self.tday = spent_on ? spent_on.day : nil
        end

        def project
          case self.entity_type
          when 'Project'
            self.entity
          when 'Issue', 'Version'
            self.entity.project
          end
        end

        def issue
          case self.entity_type
          when 'Issue'
            self.entity
          else
            nil
          end
        end

        def version
          case self.entity_type
          when 'Version'
            self.entity
          else
            nil
          end
        end

        def main_project
          self.project.root if self.project
        end

        def entity_title
          case self.entity_type
          when 'Project', 'Version'
            self.entity.name
          when 'Issue'
            self.entity.subject
          end
        end

        def attachments_visible?(user=nil)
          (user || User.current).allowed_to?(manage_permission, project)
        end

        def attachments_deletable?(user=nil)
          (user || User.current).allowed_to?(manage_permission, project)
        end

        def recipients
          project.notified_users.select{|user| user.allowed_to?(manage_permission, project)}.collect{|user| user.mail}
        end

      end
    end

  end
end

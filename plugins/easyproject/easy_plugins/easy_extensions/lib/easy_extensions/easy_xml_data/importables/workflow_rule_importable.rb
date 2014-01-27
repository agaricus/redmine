require 'easy_extensions/easy_xml_data/importables/importable'
module EasyXmlData
  class WorkflowRuleImportable < Importable
    
    def initialize(data)
      @klass = WorkflowRule
      super
      @belongs_to_associations['tracker_id'] = 'tracker'
    end
    
    def mappable?
      false
    end
    
    private
    
    def before_record_save(workflow_rule, xml, map)
      !workflow_rule.tracker_id.blank? && !workflow_rule.role_id.blank? && !workflow_rule.old_status.blank? && !workflow_rule.new_status.blank?
    end
    
  end
end
module EasyPatch
  module AccessKeysPatch
    
    def self.included(base)
       
      base.class_eval do

        remove_const(:ACCESSKEYS)
        const_set(:ACCESSKEYS, {:edit => 'e',
          :preview => 'r',
          :quick_search => 'f',
          :search => '4',
          :new_issue => 'n',
          :project_jump => 'r',
          :issue_edit => 'a',
          :issue_submit => 's'
       })


      end
      
    end
    
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::AccessKeys', 'EasyPatch::AccessKeysPatch'

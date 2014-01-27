module EasyPatch
  module VersionsHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        def versions_relations_field_tag(field_name, field_id, values = [], options = {})
          selected_values = EasyExtensions::CustomFields::EasyLookupCustomFieldFormat.entity_ids_to_lookup_values('Version', values)
          easy_modal_selector_field_tag('Version', 'link_with_name', field_name, field_id, selected_values, options)
        end

      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'VersionsHelper', 'EasyPatch::VersionsHelperPatch'

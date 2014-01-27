module EasyPatch
  module FormTagHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        
        def easy_html5_date_tag(name, value = nil, options = {})
          tag :input, { 'type' => 'date', 'name' => name, 'id' => sanitize_to_id(name), 'value' => value }.update(options.stringify_keys)
        end
        def easy_html5_datetime_tag(name, value = nil, options = {})
          tag :input, { 'type' => 'datetime', 'name' => name, 'id' => sanitize_to_id(name), 'value' => value }.update(options.stringify_keys)
        end
        
      end
    end

    module InstanceMethods

    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::FormTagHelper', 'EasyPatch::FormTagHelperPatch'

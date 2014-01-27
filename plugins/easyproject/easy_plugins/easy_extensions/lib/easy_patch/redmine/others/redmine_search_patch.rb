module EasyPatch
  module RedmineSearchPatch

    def self.included(base)
      base.class_eval do

        class << self

          def unregister(search_type)
            search_type = search_type.to_s
            available_search_types.delete(search_type)
          end

        end

      end

    end
  end

end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Search', 'EasyPatch::RedmineSearchPatch'

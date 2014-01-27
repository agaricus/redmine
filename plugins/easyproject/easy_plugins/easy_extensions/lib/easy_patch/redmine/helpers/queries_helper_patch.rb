module EasyPatch
  module QueriesHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :retrieve_query, :easy_extensions
        
      end

    end

    module InstanceMethods

      def retrieve_query_with_easy_extensions
        raise NotImplementedError
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'QueriesHelper', 'EasyPatch::QueriesHelperPatch'

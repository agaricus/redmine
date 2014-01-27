module EasyPatch
  module MimeResponds
    module CollectorPatch

      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do

          alias_method_chain :response, :easy_extensions
       
        end
      end

      module InstanceMethods
      
        def response_with_easy_extensions
          @responses[Mime::Type.lookup_by_extension('mobile')] ||= @responses[Mime::Type.lookup_by_extension('html')]
          response_without_easy_extensions
        end
      end

    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionController::MimeResponds::Collector', 'EasyPatch::MimeResponds::CollectorPatch'

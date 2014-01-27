module EasyPatch
  module RepositoryPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        safe_attributes 'easy_repository_url',
          :if => lambda {|repository, user| repository.new_record?}

      end
    end

    module InstanceMethods

    end

  end

end
EasyExtensions::PatchManager.register_model_patch 'Repository', 'EasyPatch::RepositoryPatch'

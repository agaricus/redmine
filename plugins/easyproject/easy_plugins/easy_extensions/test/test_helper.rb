require File.expand_path('../../../../../../test/test_helper', __FILE__)

#require patche modules
Dir[File.dirname(__FILE__) + '/redmine_patches/*.rb'].each {|file| require file }

class ActiveSupport::TestCase

  class_attribute :easy_fixture_path
  self.easy_fixture_path =  File.expand_path('../fixtures/', __FILE__)

  def self.easy_fixtures(*fixture_names)
    self.fixture_path = easy_fixture_path
    # fixture_names |= [:trackers] 
    self.fixtures(*fixture_names)
  end

  module EasyPatchLoader
    extend ActiveSupport::Concern

    included do
      #nic
    end

    #nevim kdy jindy, aby se to provedlo pro kazdou subclassu
    def initialize(*attrs, &block)
      self.class.include_easy_patch
      super
    end

    module ClassMethods
      def include_easy_patch
        return if @easy_patch_already_included

        @easy_patch_already_included = true
        patch_name = "EasyExtensions::#{self.name}Patch"

        patch = begin patch_name.constantize rescue nil end
        self.send(:include, patch) if patch
      end
    end

  end

  include EasyPatchLoader

end
module EasyPatch
  module DiffPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do
        alias_method_chain :initialize, :easy_extensions
      end
    end

    module InstanceMethods

      def initialize_with_easy_extensions(content_to, content_from)
        @words = Sanitize.clean(content_to, :output => :html).to_s.split(/(\s+)/)
        @words = @words.select {|word| word != ' '}
        words_from = Sanitize.clean(content_from, :output => :html).to_s.split(/(\s+)/)
        words_from = words_from.select {|word| word != ' '}
        @diff = words_from.diff @words
      end

    end
  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Helpers::Diff', 'EasyPatch::DiffPatch'

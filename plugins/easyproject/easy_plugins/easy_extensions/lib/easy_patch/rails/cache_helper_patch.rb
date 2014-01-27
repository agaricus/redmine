module EasyPatch
  module CacheHelperPatch

    def self.included(base)

      base.class_eval do

        def easy_cache(name = {}, use_cache_proc = nil, options = nil, &block)
          if use_cache_proc.is_a?(Proc)
            use_cache = use_cache_proc.call
          elsif !use_cache_proc.nil?
            use_cache = !!use_cache_proc
          else
            use_cache = !in_mobile_view?
          end

          if use_cache && EasySetting.value('use_easy_cache')
            cache(name, options, &block)
          else
            concat(capture(&block))
          end
        end

      end
    end

  end

end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Helpers::CacheHelper', 'EasyPatch::CacheHelperPatch'

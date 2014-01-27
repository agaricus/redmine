module EasyPatch
  module ActionViewPatch
    module ResolverPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do

          alias_method_chain :find_all, :easy_extensions

        end
      end

      module InstanceMethods

        def find_all_with_easy_extensions(name, prefix=nil, partial=false, details={}, key=nil, locals=[])
          cached(key, [name, prefix, partial], details, locals) do
            if details[:formats] & [:xml, :json]
              details = details.dup
              additional_formats = Array.new
              additional_formats << :html if details[:formats].include?(:mobile)
              additional_formats << :api
              details[:formats] = details[:formats].dup + additional_formats
            end
            find_templates(name, prefix, partial, details)
          end
        end

      end
    end

    module RendererPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do

          alias_method_chain :render, :easy_extensions

        end
      end

      module InstanceMethods

        def render_with_easy_extensions(context, options)
          if context.respond_to?(:in_mobile_view?) && context.in_mobile_view?
            options[:formats] ||= []
            options[:formats] = Array(options[:formats]) + [:mobile]
          end
          render_without_easy_extensions(context, options)
        end
      end
    end
  end
end
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Resolver', 'EasyPatch::ActionViewPatch::ResolverPatch'
EasyExtensions::PatchManager.register_rails_patch 'ActionView::Renderer', 'EasyPatch::ActionViewPatch::RendererPatch'

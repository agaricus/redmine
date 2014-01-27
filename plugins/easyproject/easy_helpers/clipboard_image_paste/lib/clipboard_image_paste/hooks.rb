#*******************************************************************************
# clipboard_image_paste Redmine plugin.
#
# Hooks.
#
# Authors:
# - Richard Pecl
#
# Terms of use:
# - GNU GENERAL PUBLIC LICENSE Version 2
#*******************************************************************************

module ClipboardImagePaste
  class Hooks  < Redmine::Hook::ViewListener

    # Add stylesheets and javascripts links to all pages
    # (there's no way to add them on specific existing page)
    def view_layouts_base_html_head(context={})
      format = context[:controller].params[:format]
      if format.nil? || format == 'html'
        context[:controller].send(:render_to_string, :partial => 'clipboard_image_paste/headers', :locals => context)
      end
    end

    # Render image paste form on every page,
    # javascript allows the form to show on issues, news, files, documents, wiki
    def view_layouts_base_body_bottom(context={})
      format = context[:controller].params[:format]
      if format.nil? || format == 'html'
        context[:controller].send(:render_to_string, :partial => 'clipboard_image_paste/add_form', :locals => context)
      end
    end

  end # class
end # module

module EasyPatch
  module WatchersHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :watcher_link, :easy_extensions
        alias_method_chain :watchers_list, :easy_extensions

      end
    end

    module InstanceMethods

      def watchers_list_with_easy_extensions(object)
        remove_allowed = User.current.allowed_to?("delete_#{object.class.name.underscore}_watchers".to_sym, object.project)
        lis = object.watcher_users.sorted.collect do |user|
          s = avatar(user, :size => '40').to_s + link_to_user(user, :class => 'user').to_s
          if remove_allowed
            url = {:controller => 'watchers',
              :action => 'destroy',
              :object_type => object.class.to_s.underscore,
              :object_id => object.id,
              :user_id => user}
            s += ' '.html_safe + link_to(content_tag(:span,'', :class => 'icon-del', :title => l(:button_delete)),
              url, :remote => true, :method => 'delete', :class => 'delete').html_safe
          end
          content_tag(:li, s.html_safe, :class => "user-#{user.id} easy-dropper-target easy-drop-user", :data => {:user_id => user.id, 'drop-action' => 'user'})
        end
        lis.empty? ? ''.html_safe : "<ul class='link-list'>#{ lis.join("\n") }</ul>".html_safe
      end

      def watcher_link_with_easy_extensions(objects, user)
        return '' unless user && user.logged?
        objects = Array.wrap(objects)
        watched = Watcher.any_watched?(objects, user)
        if (issues = objects.select {|object| object.is_a?(Issue)}).any?
          if watched && issues.detect{|i| !User.current.allowed_to?(:add_issue_watchers, i.project)}
            return ''
          end
          if !watched && issues.detect{|i| !User.current.allowed_to?(:add_issue_watchers, i.project)}
            return ''
          end
        end

        css = [watcher_css(objects), watched ? 'icon icon-watcher watcher-fav' : 'icon icon-watcher watcher-fav-off'].join(' ')
        text = watched ? l(:button_unwatch) : l(:button_watch)
        url = watch_path(
          :object_type => objects.first.class.to_s.underscore,
          :object_id => (objects.size == 1 ? objects.first.id : objects.map(&:id).sort)
        )
        method = watched ? 'delete' : 'post'

        link_to text, url, :remote => true, :method => method, :class => css
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'WatchersHelper', 'EasyPatch::WatchersHelperPatch'

module EasyPatch
  module RepositoriesHelperPatch

    def self.included(base)
      base.send(:include, InstanceMethods)

      base.class_eval do

        alias_method_chain :git_field_tags, :easy_extensions
      end
    end

    module InstanceMethods

      def git_field_tags_with_easy_extensions(form, repository)
        return git_field_tags_without_easy_extensions(form, repository) if !repository.new_record?
        content_tag('p', label_tag('easy_repository_source_easy_repository_url', l(:label_easy_repository_source_easy_repository_url)) +
            radio_button_tag('easy_repository_source', 'easy_repository_url', true, :disabled => !repository.safe_attribute?('easy_repository_url')) +
            form.text_field(:easy_repository_url, :no_label => true, :id => nil, :size => 60, :disabled => !repository.safe_attribute?('easy_repository_url')) +
            '<br />'.html_safe + '<em>'.html_safe +
            l(:text_git_repository_url_note) + '</em>'.html_safe
        ) +
          content_tag('p', label_tag('easy_repository_source_repository_path', l(:field_path_to_repository)) +
            radio_button_tag('easy_repository_source', 'repository_path', false, :disabled => !repository.safe_attribute?('url')) +
            form.text_field(
            :url, :no_label => true,
            :size => 60, 
            :disabled => !repository.safe_attribute?('url')
          ) +
            '<br />'.html_safe + '<em>'.html_safe +
            l(:text_git_repository_note) + '</em>'.html_safe) +
          content_tag('p', form.select(
            :path_encoding, [nil] + Setting::ENCODINGS,
            :label => l(:field_scm_path_encoding)
          ) +
            '<br />'.html_safe + l(:text_scm_path_encoding_note)) +
          content_tag('p', form.check_box(
            :extra_report_last_commit,
            :label => l(:label_git_report_last_commit)
          ))
      end

    end
  end
end
EasyExtensions::PatchManager.register_helper_patch 'RepositoriesHelper', 'EasyPatch::RepositoriesHelperPatch'

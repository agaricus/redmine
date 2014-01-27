# encoding: utf-8
module EasyPatch
  module ScmGitAdapterPatch
    def self.included(base)

      base.class_eval do

        def changeset_branches(scmid)
          branches = []
          cmd_args = %w|branch --no-color --no-abbrev --contains| << scmid
          git_cmd(cmd_args) do |io|
            io.each_line do |line|
              branch_rev = line.match('\s*(\*?)\s*(.*?)$')
              if branch_rev[2].present?
                branches << branch_rev[2].strip
              end
            end
          end
          branches.sort
        rescue ScmCommandAborted
          []
        end

      end

    end

  end
end
EasyExtensions::PatchManager.register_other_patch 'Redmine::Scm::Adapters::GitAdapter', 'EasyPatch::ScmGitAdapterPatch'

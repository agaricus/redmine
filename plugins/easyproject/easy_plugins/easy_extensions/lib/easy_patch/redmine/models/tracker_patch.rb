module EasyPatch
	module TrackerPatch

    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do

        Tracker.send(:remove_const, 'CORE_FIELDS_UNDISABLABLE')
        Tracker.send(:const_set, 'CORE_FIELDS_UNDISABLABLE', %w(author_id project_id tracker_id subject description priority_id is_private).freeze)
        Tracker.send(:remove_const, 'CORE_FIELDS_ALL')
        Tracker.send(:const_set, 'CORE_FIELDS_ALL', (Tracker::CORE_FIELDS_UNDISABLABLE + Tracker::CORE_FIELDS).freeze)

        acts_as_easy_translate
      end
    end

    module InstanceMethods

      def custom_field_mapping_data(tracker_to)
        return {} if tracker_to.blank?

        data = {}
        custom_fields.each do |cf_from|
          data[cf_from] = tracker_to.custom_fields.select{|cf_to| cf_from.field_format == cf_to.field_format}
        end
        data
      end

      def move_issues(tracker, cf_map={})
        Mailer.with_deliveries(false) do
          issues.each do |issue|
            unless tracker.project_ids.include?(issue.project_id)
              tracker.projects << issue.project
              tracker.save(:validate => false)
            end
            issue.tracker = tracker
            project = issue.project
            issue.custom_values.each do |cv|
              if cf_map[cv.custom_field_id]
                unless project.issue_custom_field_ids.include?(cf_map[cv.custom_field_id])
                  project.issue_custom_field_ids << cf_map[cv.custom_field_id]
                  project.save
                end
                cv.custom_field_id = cf_map[cv.custom_field_id]
                cv.save
              else
                if cv.destroy
                  issue.custom_values.delete(cv)
                end
              end
            end
            issue.mass_operations_in_progress = true
            issue.save(:validate => false)
          end
        end
      end

    end

  end
end
EasyExtensions::PatchManager.register_model_patch 'Tracker', 'EasyPatch::TrackerPatch'

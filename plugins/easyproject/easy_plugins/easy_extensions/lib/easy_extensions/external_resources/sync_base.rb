module EasyExtensions
  class ExternalResources::SyncBase

    def sync_all
    end

    class << self

      def internal_entity_class
        raise NotImplementedError, 'You have to override \'internal_entity_class\' method!'
      end

      def external_entity_class
        raise NotImplementedError, 'You have to override \'external_entity_class\' method!'
      end

      def get_easy_external_sync_where_scope(current_scope, external_resource_id)
        raise NotImplementedError, 'You have to override \'get_easy_external_sync_where_scope\' method!'
      end

      def get_easy_external_sync_object(external_resource_id)
        current_scope = ::EasyExternalSynchronisation.scoped
        current_scope = get_easy_external_sync_where_scope(current_scope, external_resource_id)
        current_scope = current_scope.order('synchronized_at DESC')
        current_scope.first
      end

      def logger
        @@external_resources_sync_logger ||= Logger.new(File.join(Rails.root, 'log', 'external_resources_sync.log'), 'weekly')
      end

    end

  end
end

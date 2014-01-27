require 'easy_extensions/external_resources/import_sync_base'

module EasyExtensions
  class ExternalResources::Fakturoid::FakturoidImportSyncBase < ExternalResources::ImportSyncBase

    attr_reader :fakturoid_url, :fakturoid_user, :fakturoid_password

    def set_fakturoid_credentials(url, user, password)
      @fakturoid_url, @fakturoid_user, @fakturoid_password = url, user, password
    end

    class << self

      def get_easy_external_sync_where_scope(current_scope, external_resource_id)
        current_scope = current_scope.where(:entity_type => internal_entity_class.name, :direction => ::EasyExternalSynchronisation::DIRECTION_IN,
          :external_source => 'fakturoid', :external_type => external_entity_class.name, :external_id => external_resource_id)
      end

    end

    protected

    def get_external_resources_for_sync(options={}, &block)
      self.class.external_entity_class.get_all_records(options, &block)
    end

    def ensure_connection_to_external_resource
      self.class.external_entity_class.site = @fakturoid_url
      self.class.external_entity_class.user = @fakturoid_user
      self.class.external_entity_class.password = @fakturoid_password
    end

  end
end

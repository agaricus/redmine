require 'easy_extensions/external_resources/sync_base'

module EasyExtensions
  class ExternalResources::ImportSyncBase < ExternalResources::SyncBase

    def initialize(new_record_attributes={})
      @new_record_attributes = new_record_attributes || {}
    end

    def sync_all
      self.class.logger.info "******************************" if self.class.logger
      self.class.logger.info "#{Time.now} - beginning sync all #{self.class.name}" if self.class.logger

      ensure_connection_to_external_resource

      get_external_resources_for_sync.each do |external_resource|
        sync_one(external_resource)
      end

      self.class.logger.info "#{Time.now} - end of sync #{self.class.name}" if self.class.logger
    end

    def sync_one(external_resource)
      external_resource_id = get_external_resource_id(external_resource)
      self.class.logger.info "#{Time.now} - beginning sync one #{external_resource.class.name} - (##{external_resource_id})" if self.class.logger

      easy_sync_relation = self.class.get_easy_external_sync_object(external_resource_id)

      if !easy_sync_relation.nil? && !easy_sync_relation.is_a?(::EasyExternalSynchronisation)
        raise ArgumentError, 'The method \'get_easy_sync_relation\' have to return ::EasyExternalSynchronisation object.'
      end

      current_entity = easy_sync_relation.entity if easy_sync_relation
      if current_entity.nil?
        self.class.logger.info "#{Time.now} - internal entity not found, will be created" if self.class.logger
        current_entity = create_new_internal_entity
      end

      if current_entity
        update_entity_without_save(current_entity, external_resource)

        if current_entity.save(:validate => false)
          self.class.logger.info "#{Time.now} - internal entity saved successfully #{current_entity.class.name} - (##{current_entity.id})" if self.class.logger
          save_easy_external_sync_object(easy_sync_relation, current_entity, external_resource_id, EasyExternalSynchronisation::STATUS_OK)
        else
          self.class.logger.info "#{Time.now} - internal entity NOT saved #{current_entity.class.name} - (##{current_entity.id})" if self.class.logger
          save_easy_external_sync_object(easy_sync_relation, current_entity, external_resource_id, EasyExternalSynchronisation::STATUS_ERROR, current_entity.errors.full_messages.join(', '))
        end

      end

      self.class.logger.info "#{Time.now} - end of sync one #{external_resource.class.name} - (##{external_resource_id})" if self.class.logger

      return current_entity
    end

    protected

    def get_external_resources_for_sync(options={}, &block)
      raise NotImplementedError, 'You have to override \'get_external_resources_for_sync\' method!'
    end

    def update_entity_without_save(current_entity, external_resource)
      raise NotImplementedError, 'You have to override \'update_entity_without_save\' method!'
    end

    def build_easy_external_sync_object(current_entity, external_resource_id)
      current_scope = current_entity.easy_external_synchronisations.scoped
      current_scope = self.class.get_easy_external_sync_where_scope(current_scope, external_resource_id)

      easy_sync_relation = current_scope.build
      easy_sync_relation.entity = current_entity

      return easy_sync_relation
    end

    def create_new_internal_entity
      self.class.internal_entity_class.new(@new_record_attributes)
    end

    def get_external_resource_id(external_resource)
      external_resource.id
    end

    def ensure_connection_to_external_resource
    end

    private

    def save_easy_external_sync_object(easy_sync_relation, current_entity, external_resource_id, status = EasyExternalSynchronisation::STATUS_OK, note = nil)
      if easy_sync_relation.nil?
        easy_sync_relation = build_easy_external_sync_object(current_entity, external_resource_id)
      end

      easy_sync_relation.entity ||= current_entity
      easy_sync_relation.status = status
      easy_sync_relation.note = note
      easy_sync_relation.synchronized_at = Time.now
      easy_sync_relation.save!

      return easy_sync_relation
    end

  end
end

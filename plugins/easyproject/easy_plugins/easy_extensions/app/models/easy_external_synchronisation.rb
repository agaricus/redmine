class EasyExternalSynchronisation < ActiveRecord::Base

  belongs_to :entity, :polymorphic => true

  STATUS_OK = 1
  STATUS_ERROR = 9
  DIRECTION_IN = 'in'
  DIRECTION_OUT = 'out'

  def direction=(dir)
    super(dir.to_s == 'out' ? DIRECTION_OUT : DIRECTION_IN)
  end

  def self.create_ok(external_type, external_id, external_source, entity, direction = :in)
    s = EasyExternalSynchronisation.new
    s.external_type = external_type
    s.external_id = external_id
    s.external_source = external_source
    s.entity = entity
    s.status = STATUS_OK
    s.direction = direction
    s.synchronized_at = Time.now
    s.save!
    s
  end

  def self.create_error(external_type, external_id, external_source, note = nil, entity = nil, direction = :in)
    s = EasyExternalSynchronisation.new
    s.external_type = external_type
    s.external_id = external_id
    s.external_source = external_source
    s.entity = entity
    s.status = STATUS_ERROR
    s.direction = direction
    s.note = note
    s.synchronized_at = Time.now
    s.save!
    s
  end

  def self.find_last_entity(external_type, external_id, external_source = nil)
    s = EasyExternalSynchronisation.where(:external_type => external_type, :external_id => external_id, :external_source => external_source, :status => STATUS_OK).order('synchronized_at DESC').first
    s.entity if s
  end

end

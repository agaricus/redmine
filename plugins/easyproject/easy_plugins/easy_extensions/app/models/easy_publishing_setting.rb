class EasyPublishingSetting < ActiveRecord::Base
  belongs_to :easy_publishing_module

  validates :easy_publishing_module, :url, :presence => true
  validate :validate

  before_validation :parse_url

  scope :infos, lambda { { :conditions => ["#{EasyPublishingModule.table_name}.name = ?", 'info'], :include => :easy_publishing_module } }
  scope :contacts, lambda { { :conditions => ["#{EasyPublishingModule.table_name}.name = ?", 'contact'], :include => :easy_publishing_module } }
  scope :helps, lambda { { :conditions => ["#{EasyPublishingModule.table_name}.name = ?", 'help'], :include => :easy_publishing_module } }
  scope :youtubes, lambda { { :conditions => ["#{EasyPublishingModule.table_name}.name = ?", 'youtube'], :include => :easy_publishing_module } }

  acts_as_attachable

  def parse_url
    self.controller = ''
    self.action = ''
    if url =~ URI::regexp && path = URI::parse(url).path
      begin
        route_hash =  Rails.application.routes.recognize_path(path)
      rescue ActionController::RoutingError => e
        return
      end
      self.action = route_hash[:action]
      self.controller = route_hash[:controller]
    end
  end

  def validate
    if (self.controller == '' || self.action == '') && self.url != '*'
      errors.add :url, :invalid
    end
  end

  def validate_attachments
    invalid_attachments_names = []
    self.attachments.each do |a|
      if a.content_type && !a.content_type.start_with?('image')
        invalid_attachments_names << a.filename
        a.destroy
      end
    end
    invalid_attachments_names
  end

  def project
    nil
  end

  def attachments_visible?(user = User.current)
    true
  end

  def attachments_deletable?(user = User.current)
    true
  end

  def self.editable?(user = User.current)
    user && (user.login == 'admin')
  end

  def hide_helpbubble?(user=nil)
    user ||= User.current
    if pref = user.preference.others[:easy_publishing_state]
      return !pref[self.id.to_s].nil? && pref[self.id.to_s]
    else
      return false
    end
  end

end

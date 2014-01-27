class EasyBlockMailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues
  helper :custom_fields

  include Redmine::I18n

  def self.default_url_options
    { :host => Setting.host_name, :protocol => Setting.protocol }
  end

  # Activates/desactivates email deliveries during +block+
  def self.with_deliveries(enabled = true, &block)
    was_enabled = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = !!enabled
    yield
  ensure
    ActionMailer::Base.perform_deliveries = was_enabled
  end

  # Sends emails synchronously in the given block
  def self.with_synched_deliveries(&block)
    saved_method = ActionMailer::Base.delivery_method
    if m = saved_method.to_s.match(%r{^async_(.+)$})
      ActionMailer::Base.delivery_method = m[1].to_sym
    end
    yield
  ensure
    ActionMailer::Base.delivery_method = saved_method
  end

  def mail(headers={}, &block)
    default_headers = {'X-Mailer' => 'Redmine',
      'X-Redmine-Host' => Setting.host_name,
      'X-Redmine-Site' => Setting.app_title,
      'X-Auto-Response-Suppress' => 'OOF',
      'Auto-Submitted' => 'auto-generated',
      'From' => headers[:from] || Setting.mail_from,
      'List-Id' => "<#{Setting.mail_from.to_s.gsub('@', '.')}>"}

    headers = default_headers.merge(headers)

    # Removes the author from the recipients and cc
    # if the author does not want to receive notifications
    # about what the author do
    if @author && @author.logged? && @author.pref.no_self_notified
      headers[:to].delete(@author.mail) if headers[:to].is_a?(Array)
      headers[:cc].delete(@author.mail) if headers[:cc].is_a?(Array)
    end

    if @author && @author.logged?
      redmine_headers 'Sender' => @author.login
    end

    # Blind carbon copy recipients
    if Setting.bcc_recipients?
      headers[:bcc] = [headers[:to], headers[:cc]].flatten.uniq.reject(&:blank?)
      headers[:to] = nil
      headers[:cc] = nil
    end

    if @message_id_object
      headers[:message_id] = "<#{self.class.message_id_for(@message_id_object)}>"
    end
    if @references_objects
      headers[:references] = @references_objects.collect {|o| "<#{self.class.references_for(o)}>"}.join(' ')
    end

    if block.nil?
      current_mail = super headers do |format|
        format.text
        format.html unless Setting.plain_text_mail?
      end
    else
      current_mail = super(headers, &block)
    end

    set_language_if_valid @initial_language
    current_mail
  end

  def initialize(*args)
    @initial_language = current_language
    set_language_if_valid Setting.default_language
    super
  end

  def self.deliver_mail(mail)
    return false if mail.to.blank? && mail.cc.blank? && mail.bcc.blank?
    begin
      # Log errors when raise_delivery_errors is set to false, Rails does not
      mail.raise_delivery_errors = true
      super
    rescue Exception => e
      if ActionMailer::Base.raise_delivery_errors
        raise e
      else
        Rails.logger.error "Email delivery error: #{e.message}"
      end
    end
  end

  private

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v.to_s }
  end

  def self.token_for(object, rand=true)
    if object.respond_to?(:created_at) || object.respond_to?(:updated_at)
      timestamp = object.send(object.respond_to?(:created_at) ? :created_at : :updated_at)
    else
      timestamp = object.send(object.respond_to?(:created_on) ? :created_on : :updated_on)
    end
    hash = [
      "redmine",
      "#{object.class.name.demodulize.underscore}-#{object.id}",
      timestamp.strftime("%Y%m%d%H%M%S")
    ]
    if rand
      hash << Redmine::Utils.random_hex(8)
    end
    host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
    host = "#{::Socket.gethostname}.redmine" if host.empty?
    "#{hash.join('.')}@#{host}"
  end

  # Returns a Message-Id for the given object
  def self.message_id_for(object)
    token_for(object, true)
  end

  # Returns a uniq token for a given object referenced by all notifications
  # related to this object
  def self.references_for(object)
    token_for(object, false)
  end

  def message_id(object)
    @message_id_object = object
  end

  def references(object)
    @references_objects ||= []
    @references_objects << object
  end

  def mylogger
    Rails.logger
  end
end

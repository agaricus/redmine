class EasyExternalAuthentication < ActiveRecord::Base
  belongs_to :user

  def self.clear_providers
    logger.debug 'Cleared providers of oauth'
    @@providers = nil
  end

  def self.providers
    @@providers ||= @@provider_classes.collect {|listener| listener.instance}
  end

  def self.add_provider(klass)
    @@provider_classes ||= []
    @@provider_classes << klass
    clear_providers
  end

  def self.get_provider(name)
    providers.detect{|provider| provider.name == name}
  end

  def provider_klass
    self.class.get_provider(provider)
  end

  def client
    provider_klass.client(self.access_token)
  end

end
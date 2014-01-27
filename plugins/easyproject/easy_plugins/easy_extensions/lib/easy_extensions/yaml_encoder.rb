require 'yaml'
class YamlEncoder

  def initialize
    # structure is {version => {class => [attribute]}}
    @serialized = {
      0 => {
        EasyPageZoneModule => [:settings],
        EasyQuery => [:filters, :settings],
        CustomField => [:possible_values, :settings],
        Query => [:filters]
      }
    }
  end

  def repair
    return if RUBY_VERSION < '1.9'

    version_from = current_version
    version_to = last_version

    return if version_to <= current_version

    YAML::ENGINE.yamler = 'syck'

    version = version_from + 1
    repair_settings if version == 0
    while version <= version_to
      @serialized[version].each do |klass, attributes|
        repair_serialized_attributes(klass, attributes)
      end
      version += 1
    end

    YAML::ENGINE.yamler = 'psych'
    mark_repair_as_done(version - 1)
  end

  private

  def mark_repair_as_done(version)
    params = {:name => 'serialized_attributes_repaired'}
    setting = EasySetting.first(:conditions => params) || EasySetting.new(params)
    setting.value = version
    setting.save
  end

  def current_version
    cv = -1
    if setting = EasySetting.first(:conditions => {:name => 'serialized_attributes_repaired'})
      cv = 0
      if setting.value.is_a? Fixnum
        cv = setting.value
      end
    end
    cv
  end

  def last_version
    @serialized.keys.length - 1
  end

  def repair_serialized_attributes(klass, attributes)
    klass.all.each do |record|
      begin
        attributes.each do |a|
          record.update_column(a, Psych.dump(record.send(a)))
        end    
      rescue Exception => e
        pp 'ERROR!'
        pp record
        pp e
        pp ''
      end
    end
  end

  def repair_settings
    Setting.all.each do |setting|
      if v = setting.read_attribute(:value)
        if Setting.available_settings[setting.name] && Setting.available_settings[setting.name]['serialized'] && v.is_a?(String) 
          v = setting.value
          setting.update_column(:value, Psych.dump(v))
        end
      end
    end
  end

end
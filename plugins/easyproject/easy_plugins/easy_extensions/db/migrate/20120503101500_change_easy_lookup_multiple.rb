class ChangeEasyLookupMultiple < ActiveRecord::Migration

  def self.up
    CustomField.find(:all, :conditions => {:field_format => 'easy_lookup'}).each do |cf|
      cf.settings['multiple'] ||= '1'
      cf.save!
    end
  end

  def self.down
  end

end
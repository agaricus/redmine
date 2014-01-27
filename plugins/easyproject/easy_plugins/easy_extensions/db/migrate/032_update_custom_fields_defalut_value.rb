class UpdateCustomFieldsDefalutValue < ActiveRecord::Migration

  def self.up
    CustomField.all.each do |cf|
      next unless cf.default_value.nil?
      if cf.field_format == 'bool'
        cf.default_value = '0'
      else
        cf.default_value = ''
      end
      cf.save
    end
  end

  def self.down
  end

end
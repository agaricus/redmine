require 'yaml'
class UpdateEasyLookupValues < ActiveRecord::Migration
  def up
    CustomField.where(:field_format => 'easy_lookup').each do |cf|
      cf.custom_values.each do |cv|

        value = YAML.load(cv.value)
        next unless value.is_a?(Hash)

        unless value['selected_value'].blank?
          value['selected_value'].each do |v, vals|
            target = CustomValue.create(:customized_id => cv.customized_id, :customized_type => cv.customized_type, :custom_field => cf, :value => v)
          end
        end

        cv.destroy
      end
      cf.multiple = ( cf.settings.delete('multiple') == '1' ) if cf.settings['multiple']
      cf.save
    end
  end

  def down
  end
end

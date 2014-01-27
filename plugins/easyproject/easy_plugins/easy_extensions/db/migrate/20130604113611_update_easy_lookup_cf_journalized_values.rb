class UpdateEasyLookupCfJournalizedValues < ActiveRecord::Migration
  def up
    cfs = CustomField.where(:field_format => 'easy_lookup').all
    JournalDetail.where(:property => 'cf', :prop_key => cfs ).each do |detail|

      if detail.old_value
        old_val = YAML.load(detail.old_value)

        if old_val.is_a?(Hash) && !old_val['selected_value'].blank?
          old_val_ary = old_val['selected_value'].keys
        else
          old_val_ary = []
        end
      else
        old_val = nil
        old_val_ary = []
      end

      if detail.value
        value = YAML.load(detail.value)

        if value.is_a?(Hash) && !value['selected_value'].blank?
          value_ary = value['selected_value'].keys
        else
          value_ary = []
        end
      else
        value = nil
        value_ary = []
      end

      next if !( old_val.nil? || old_val.is_a?(Hash) )  || !( value.nil? || value.is_a?(Hash) ) || (old_val.nil? && value.nil?)

      if cfs.detect{|cf| cf.id.to_i == detail.prop_key.to_i }.multiple?
        (old_val_ary - value_ary).each do |old_id|
          JournalDetail.create( :journal_id => detail.journal_id, :property => detail.property, :prop_key => detail.prop_key, :old_value => old_id )
        end
        (value_ary - old_val_ary).each do |new_id|
          JournalDetail.create( :journal_id => detail.journal_id, :property => detail.property, :prop_key => detail.prop_key, :value => new_id )
        end
        detail.destroy
      else
        detail.update_attributes( :old_value => old_val_ary.first, :value => value_ary.first )
      end

    end
  end

  def down
  end
end

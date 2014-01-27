class ChangeEasySettingsValues < ActiveRecord::Migration
  def up
    EasySetting.where(:name => 'quick_jump_to_an_issue').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

    EasySetting.where(:name => 'use_easy_cache').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

    EasySetting.where(:name => 'avatar_enabled').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

    EasySetting.where(:name => 'show_personal_statement').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

    EasySetting.where(:name => 'show_bulk_time_entry').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

    EasySetting.where(:name => 'enable_private_issues').all.each do |s|
      if s.value.is_a?(String)
        s.value = s.value.to_boolean
        s.save!
      end
    end

  end

  def down
  end
end

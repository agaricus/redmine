# encoding: utf-8
class AddCfExternalEmail < ActiveRecord::Migration
  def up
    IssueCustomField.reset_column_information
    IssueCustomField.create(:name => 'Kopie úkolu na e-mail', :field_format => 'email', :non_deletable => true, :internal_name => 'external_mails')
  end

  def down
  end
end

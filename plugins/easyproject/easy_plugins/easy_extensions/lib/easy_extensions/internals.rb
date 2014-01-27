module EasyExtensions

  def self.cf_external_mails
    @@cf_external_mails = IssueCustomField.where(:internal_name => 'external_mails').select(:id).first
  end

end

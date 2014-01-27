module EasyExtensions

  class EasyMailTemplate

    attr_accessor :mail_sender, :mail_recepient, :mail_cc, :mail_subject, :mail_body_html, :mail_body_plain,
      :email_header, :email_footer

    def self.from_params(params)
      t = EasyExtensions::EasyMailTemplate.new
      t.mail_sender = params[:mail_sender]
      t.mail_recepient = params[:mail_recepient]
      t.mail_cc = params[:mail_cc]
      t.mail_subject = params[:mail_subject]
      t.mail_body_html = params[:mail_body_html]
      t.mail_body_plain = params[:mail_body_plain]
      t
    end

    def self.from_issue(issue)
      t = EasyExtensions::EasyMailTemplate.new
      t.mail_sender = Setting.mail_from
      t.mail_recepient = issue.custom_field_value(EasyExtensions.cf_external_mails)
      t
    end

  end

end
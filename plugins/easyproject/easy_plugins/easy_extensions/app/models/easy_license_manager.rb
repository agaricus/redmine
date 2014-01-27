class EasyLicenseManager

  def self.has_license_limit?(license_key)
    method = "validate_#{license_key.to_s}".to_sym

    return send(method) if respond_to?(method)
  end

  private

  def self.validate_user_limit
    settings = EasySetting.value('user_limit').to_i
    c = User.active.size
    if settings == 0 || settings > c
      return true
    else
      return false
    end
  end

end

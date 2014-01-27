namespace :easyproject do
  namespace :users do

    desc <<-END_DESC
    Get user's last login on and return YYYY-MM-DD.

    Example:
      bundle exec rake easyproject:users:get_last_login_on (login=manazer)
      bundle exec rake easyproject:users:get_last_login_on login=user_login
    END_DESC

    task :get_last_login_on => :environment do
      options = {}
      options[:login] = ENV['login'] ? ENV['login'].to_s : 'manazer'
      user = User.where(:login => options[:login]).first

      if user
        if user.last_login_on
          puts 'last_login_on => ' + user.last_login_on.to_s
        else
          puts 'last_login_on => null'
        end
      else
        fail 'Error: User not found!'
      end
    end

    desc <<-END_DESC
    Update user's attributes(firstname, lastname, mail).

    Example:
      bundle exec rake easyproject:users:update_attributes (login=manazer) firstname=user_firstname lastname=user_lastname mail=user_mail
      bundle exec rake easyproject:users:update_attributes login=user_login firstname=user_firstname lastname=user_lastname mail=user_mail
    END_DESC

    task :update_attributes => :environment do
      attributes = {}

      if ENV['firstname'].blank?
        attributes[:firstname] = '.'
      else
        attributes[:firstname] = ENV['firstname'].to_s
      end

      if ENV['lastname'].blank?
        attributes[:lastname] = '.'
      else
        attributes[:lastname] = ENV['lastname'].to_s
      end

      if !ENV['mail'].blank?
        attributes[:mail] = ENV['mail'].to_s
      end

      begin
        attributes[:last_login_on] = ENV['last_login_on'].blank? ? nil : ENV['last_login_on'].to_datetime
      rescue
        fail 'Error: Wrong datetime format [YYYY-MM-DD]!'
        next
      end

      user = User.where(:login => ENV['login'].to_s).first unless ENV['login'].blank?
      user ||= User.where(:login => 'manager').first
      user ||= User.where(:login => 'manazer').first

      if user
        user.attributes = attributes
        user.save

        if user.errors.size > 0
          fail 'Error (saving user):' + user.errors.full_messages.join('; ')
        end

        unless ENV['autologin_key'].blank?
          t = user.api_token || Token.new(:action => 'api', :user_id => user.id)
          t.value = ENV['autologin_key'].to_s
          t.save

          if t.errors.size > 0
            fail 'Error (saving token):' + t.errors.full_messages.join('; ')
          end
        end
      else
        fail 'Error: User not found!'
      end
    end

    desc <<-END_DESC
    Update languages to all users and system language

    Example:
      bundle exec rake easyproject:users:update_langs lang=en
    END_DESC
    task :update_langs => :environment do
      unless ENV['lang'].blank?
        fail 'Error: lang is invalid!' unless ::I18n.available_locales.include?(ENV['lang'].to_sym)

        User.update_all(:language => ENV['lang'])

        if s = Setting.where(:name => 'default_language').first
          s.value = ENV['lang']
          s.save
        else
          Setting.create(:name => 'default_language', :value => ENV['lang'])
        end
      end

    end

  end
end
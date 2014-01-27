module HelperMethods

  def setup_easyproject_app
    Setting.login_required = '1'
    Setting.text_formatting = 'HTML'
  end

  def with_settings(options, &block)
    saved_settings = options.keys.inject({}) do |h, k|
      h[k] = case Setting[k]
        when Symbol, false, true, nil
          Setting[k]
        else
          Setting[k].dup
        end
      h
    end
    options.each {|k, v| Setting[k] = v}
    yield
  ensure
    saved_settings.each {|k, v| Setting[k] = v} if saved_settings
  end

  def with_easy_settings(options, project=nil, &block)
    saved_settings = options.keys.inject({}) do |h, k|
      value = EasySetting.value(k, project)
      h[k] = case value
        when Symbol, false, true, nil
          value
        else
          value.dup
        end
      h
    end
    options.each do |k, v|
      set = EasySetting.where(:name => k, :project_id => project.try(:id)).first
      set ||= EasySetting.new(:name => k, :project => project)
      set.value = v
      set.save
    end

    yield
  ensure
    if saved_settings
      saved_settings.each do |k, v|
        set = EasySetting.where(:name => k, :project_id => project.try(:id)).first
        set.value = v
        set.save
      end
    end
  end

  # Yields the block with user as the current user
  def with_current_user(user, &block)
    saved_user = User.current
    User.current = user
    yield
  ensure
    User.current = saved_user
  end

  def logged_user(user)
    User.stubs(:current).returns(user)
  end

  # fills a CKeditor with content of with
  def fill_in_ckeditor(identification, options={})
    raise "You have to provide an options hash containing :with" unless options.is_a?(Hash) && options[:with]

    content = options.fetch(:with).to_json
    if options[:context]
      case identification
      when Fixnum
        locator = ":first" if identification == 1
        locator ||= ":last"
        page.execute_script <<-SCRIPT
          var locator = jQuery("#{options[:context]}").find('textarea#{locator}').attr('id');
          CKEDITOR.instances[locator].setData(#{content});
        SCRIPT
      when String
        page.execute_script <<-SCRIPT
          CKEDITOR.instances[#{identification}].setData(#{content});
        SCRIPT
      end
    end
  end

end

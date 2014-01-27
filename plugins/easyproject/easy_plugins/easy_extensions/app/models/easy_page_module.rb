class EasyPageModule < ActiveRecord::Base
  self.table_name = 'easy_page_modules'

  has_many :available_in_pages, :class_name => "EasyPageAvailableModule", :foreign_key => 'easy_page_modules_id', :dependent => :destroy
  has_many :all_modules, :through => :available_in_pages, :dependent => :destroy
  has_many :all_template_modules, :through => :available_in_pages, :dependent => :destroy

  attr_accessor :page_zone_module, :template_zone_module

  def self.install_to_page(page_or_page_name)
    raise ArgumentError, 'Cannot install EasyPageModule. Use inherited class instead' if self.class.is_a?(EasyPageModule)

    if page_or_page_name.is_a?(EasyPage) && !page_or_page_name.new_record?
      easy_page = page_or_page_name
    else
      easy_page = EasyPage.where(:page_name => page_or_page_name.to_s).first
    end

    return false if !easy_page.is_a?(EasyPage)

    self.create! if self.first.nil?

    epm = self.first
    EasyPageAvailableModule.create!(:easy_pages_id => easy_page.id, :easy_page_modules_id => epm.id) if EasyPageAvailableModule.where(:easy_pages_id => easy_page.id, :easy_page_modules_id => epm.id).count == 0

    return true
  end

  def module_name
    @module_name ||= self.class.name.underscore.gsub(/epm_/, '')
  end

  def category_name
    raise ArgumentError, 'The category name cannot be null.'
  end

  def show_path
    @show_path ||= "easy_page_modules/#{category_name}/#{module_name}_show"
  end

  def edit_path
    @edit_path ||= "easy_page_modules/#{category_name}/#{module_name}_edit"
  end

  def get_show_data(settings, user, page_context = {})
    nil
  end

  def get_edit_data(settings, user, page_context = {})
    nil
  end

  def default_settings
    @default_settings ||= HashWithIndifferentAccess.new
  end

  def permissions
    []
  end

  def runtime_permissions(user)
    true
  end

  def translated_name
    @translated_name ||= l("easy_pages.modules.#{module_name}").html_safe
  end

  def module_allowed?(user = nil)
    user ||= User.current

    if self.permissions.blank?
      perm = true
    else
      perm = self.permissions.inject(true) do |allowed, perm|
        allowed && user.allowed_to?(perm, nil, :global => true)
      end
    end

    return false unless perm

    return (runtime_permissions(user) == true)
  end

end


require_dependency 'utils/blockutils'

class EasyPageZoneModule < ActiveRecord::Base
  include EasyUtils::BlockUtils
  include Redmine::I18n

  self.table_name = 'easy_page_zone_modules'
  self.primary_key = 'uuid'

  belongs_to :page_definition, :class_name => "EasyPage", :foreign_key => 'easy_pages_id'
  belongs_to :available_zone, :class_name => "EasyPageAvailableZone", :foreign_key => 'easy_page_available_zones_id'
  belongs_to :available_module, :class_name => "EasyPageAvailableModule", :foreign_key => 'easy_page_available_modules_id'
  belongs_to :user, :class_name => "User", :foreign_key => 'user_id'
  has_one :zone_definition, :class_name => 'EasyPageZone', :through => :available_zone
  has_one :module_definition, :class_name => 'EasyPageModule', :through => :available_module

  acts_as_list

  serialize :settings, Hash

  before_save :generate_modul_uuid
  after_initialize :default_values

  def self.delete_modules(easy_page, user_id = nil, entity_id = nil, tab_id = nil)
    return unless easy_page.is_a?(EasyPage)

    epzm_scope = EasyPageZoneModule.scoped
    epzm_scope = epzm_scope.where(:easy_pages_id => easy_page.id)
    if user_id.blank?
      epzm_scope = epzm_scope.where(:user_id => nil)
    else
      epzm_scope = epzm_scope.where(:user_id => user_id)
    end
    if entity_id.blank?
      epzm_scope = epzm_scope.where(:entity_id => nil)
    else
      epzm_scope = epzm_scope.where(:entity_id => entity_id)
    end
    epzm_scope = epzm_scope.where(:tab_id => tab_id) if tab_id

    epzm_scope.delete_all

    if !tab_id.nil? && EasyPageUserTab.table_exists?
      # eput_scope = EasyPageUserTab.scoped
      # eput_scope = eput_scope.where(:page_id => easy_page.id)
      # if user_id.blank?
      #   eput_scope = eput_scope.where(:user_id => nil)
      # else
      #   eput_scope = eput_scope.where(:user_id => user_id)
      # end
      # if entity_id.blank?
      #   eput_scope = eput_scope.where(:entity_id => nil)
      # else
      #   eput_scope = eput_scope.where(:entity_id => entity_id)
      # end
      # eput_scope = eput_scope.where(:position => tab)

      # eput_scope.delete_all

      EasyPageUserTab.destroy(tab_id)
    end
  end

  def self.create_from_page_template(page_template, user_id=nil, entity_id=nil)
    return unless page_template.is_a?(EasyPageTemplate)

    easy_page = page_template.page_definition

    EasyPageZoneModule.delete_modules(easy_page, user_id, entity_id)

    EasyPageUserTab.where(:page_id => easy_page.id, :user_id => user_id, :entity_id => entity_id).destroy_all

    if EasyPageTemplateTab.table_exists?
      tab_id_mapping = {}
      EasyPageTemplateTab.page_template_tabs(page_template, nil).each do |page_template_tab|
        page_tab = EasyPageUserTab.new(:page_id => easy_page.id, :user_id => user_id, :entity_id => entity_id, :name => page_template_tab.name)
        page_tab.save!
        tab_id_mapping[page_template_tab.id] = page_tab.id
      end
    end

    EasyPageTemplateModule.where(:easy_page_templates_id => page_template.id).order(:easy_page_available_zones_id, :position).all.each do |template_module|
      if EasyPageUserTab.table_exists?
        page_module = EasyPageZoneModule.new(:easy_pages_id => easy_page.id, :easy_page_available_zones_id => template_module.easy_page_available_zones_id, :easy_page_available_modules_id => template_module.easy_page_available_modules_id, :user_id => user_id, :entity_id => entity_id, :position => template_module.position, :settings => template_module.settings, :tab_id => tab_id_mapping[template_module.tab_id])
      else
        page_module = EasyPageZoneModule.new(:easy_pages_id => easy_page.id, :easy_page_available_zones_id => template_module.easy_page_available_zones_id, :easy_page_available_modules_id => template_module.easy_page_available_modules_id, :user_id => user_id, :entity_id => entity_id, :position => template_module.position, :settings => template_module.settings)
      end

      page_module.save!
    end
  end

  def self.clone_by_entity_id(old_entity_id, new_entity_id)
    EasyPageZoneModule.where(:entity_id => old_entity_id).order(:easy_page_available_zones_id, :position).all.each do |old_page_module|
      new_page_module = old_page_module.dup
      new_page_module.entity_id = new_entity_id
      new_page_module.generate_modul_uuid(true)

      new_page_module.save!
    end

    EasyPageUserTab.where(:entity_id => old_entity_id).order(:page_id, :position).all.each do |old_tab|
      new_tab = old_tab.dup
      new_tab.entity_id = new_entity_id
      new_tab.save!
    end
  end

  # Overrides acts_as_list - scope_condition
  def scope_condition
    cond = "#{EasyPageZoneModule.table_name}.easy_pages_id = #{self.easy_pages_id} AND #{EasyPageZoneModule.table_name}.easy_page_available_zones_id = #{self.easy_page_available_zones_id}"
    cond << (self.user_id.blank? ? " AND #{EasyPageZoneModule.table_name}.user_id IS NULL" :  " AND #{EasyPageZoneModule.table_name}.user_id = #{self.user_id}")
    cond << (self.entity_id.blank? ?  " AND #{EasyPageZoneModule.table_name}.entity_id IS NULL" :  " AND #{EasyPageZoneModule.table_name}.entity_id = #{self.entity_id}")
    cond
  end

  def default_values
    self.settings ||= {}
  end

  def generate_modul_uuid(force = false)
    if force
      self.uuid = generate_uuid.dasherize
    else
      self.uuid ||= generate_uuid.dasherize
    end
  end

  def module_name
    @module_name ||= "#{self.module_definition.module_name.underscore}_#{self.uuid.underscore}"
  end

  # proxy
  def get_show_data(user, params_settings = nil, page_context = {})
    module_definition.page_zone_module = self
    module_definition.get_show_data(default_settings.merge(settings).merge(params_settings || {}), user, page_context || {})
  end

  # proxy
  def get_edit_data(user, params_settings = nil, page_context = {})
    module_definition.page_zone_module = self
    module_definition.get_edit_data(default_settings.merge(settings).merge(params_settings || {}), user, page_context || {})
  end

  private

  def default_settings
    {
      'query_type' => '2',
      'query_name' => l('easy_page_module.issue_query.adhoc_query_default_text')
    }
  end

end


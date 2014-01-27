require_dependency 'utils/blockutils'

class EasyPageTemplateModule < ActiveRecord::Base
  include EasyUtils::BlockUtils
  include Redmine::I18n
  extend EasyUtils::BlockUtils

  self.table_name = 'easy_page_template_modules'
  self.primary_key = 'uuid'

  belongs_to :template_definition, :class_name => "EasyPageTemplate", :foreign_key => 'easy_page_templates_id'
  belongs_to :available_zone, :class_name => "EasyPageAvailableZone", :foreign_key => 'easy_page_available_zones_id'
  belongs_to :available_module, :class_name => "EasyPageAvailableModule", :foreign_key => 'easy_page_available_modules_id'
  has_one :page_definition, :class_name => "EasyPage", :through => :template_definition
  has_one :zone_definition, :class_name => 'EasyPageZone', :through => :available_zone
  has_one :module_definition, :class_name => 'EasyPageModule', :through => :available_module

  acts_as_list

  serialize :settings, Hash

  before_save :generate_modul_uuid
  after_initialize :default_values

  def self.delete_modules(easy_page_template, entity_id = nil, tab_id = nil)
    return unless easy_page_template.is_a?(EasyPageTemplate)

    eptm_scope = EasyPageTemplateModule.scoped
    eptm_scope = eptm_scope.where(:easy_page_templates_id => easy_page_template.id)
    if entity_id.blank?
      eptm_scope = eptm_scope.where(:entity_id => nil)
    else
      eptm_scope = eptm_scope.where(:entity_id => entity_id)
    end
    eptm_scope = eptm_scope.where(:tab_id => tab_id) if tab_id

    eptm_scope.delete_all

    if !tab_id.nil? && EasyPageTemplateTab.table_exists?
      # eptt_scope = EasyPageTemplateTab.scoped
      # eptt_scope = eptt_scope.where(:page_template_id => easy_page_template.id)
      # if entity_id.blank?
      #   eptt_scope = eptt_scope.where(:entity_id => nil)
      # else
      #   eptt_scope = eptt_scope.where(:entity_id => entity_id)
      # end

      # eptt_scope.delete_all
      EasyPageTemplateTab.where(:id => tab_id).destroy_all
    end
  end

  def self.create_template_module(page, page_template, page_module, zone_name, settings, position)
    return nil unless page.is_a?(EasyPage)
    return nil unless page_template.is_a?(EasyPageTemplate)
    return nil unless page_module.is_a?(EasyPageModule)

    page_available_module_id = EasyPageAvailableModule.where(:easy_pages_id => page.id, :easy_page_modules_id => page_module.id).limit(1).pluck(:id).first
    page_zone_id = EasyPageZone.where(:zone_name => zone_name).limit(1).pluck(:id).first
    page_available_zone_id = EasyPageAvailableZone.where(:easy_pages_id => page.id, :easy_page_zones_id => page_zone_id).limit(1).pluck(:id).first

    EasyPageTemplateModule.create(:easy_page_templates_id => page_template.id, :easy_page_available_zones_id => page_available_zone_id, :easy_page_available_modules_id => page_available_module_id, :uuid => generate_uuid, :entity_id => nil, :settings => settings, :position => position)
  end

  # Overrides acts_as_list - scope_condition
  def scope_condition
    cond = "#{EasyPageTemplateModule.table_name}.easy_page_templates_id = #{self.easy_page_templates_id} AND #{EasyPageTemplateModule.table_name}.easy_page_available_zones_id = #{self.easy_page_available_zones_id}"
    cond << (self.entity_id.blank? ?  " AND #{EasyPageTemplateModule.table_name}.entity_id IS NULL" :  " AND #{EasyPageTemplateModule.table_name}.entity_id = #{self.entity_id}")
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
    module_definition.template_zone_module = self
    module_definition.get_show_data(default_settings.merge(settings).merge(params_settings || {}), user, page_context || {})
  end

  # proxy
  def get_edit_data(user, params_settings = nil, page_context = {})
    module_definition.template_zone_module = self
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


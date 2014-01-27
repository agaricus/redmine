class EasyPageTemplate < ActiveRecord::Base
  self.table_name = 'easy_page_templates'
  default_scope :order => "#{EasyPageTemplate.table_name}.position ASC"

  belongs_to :page_definition, :class_name => 'EasyPage', :foreign_key => 'easy_pages_id'
  has_many :easy_page_template_tabs, :class_name => 'EasyPageTemplateTab', :foreign_key => 'page_template_id', :dependent => :destroy

  acts_as_list :scope => 'easy_pages_id = #{easy_pages_id}'

  validates_length_of :template_name, :in => 1..50, :allow_nil => false
  validates_length_of :description, :in => 0..255, :allow_nil => true

  def self.default_template_for_page(page)
    return nil unless page.is_a?(EasyPage)
    EasyPageTemplate.where(:easy_pages_id => page.id).where(:is_default => true).first
  end

  def before_save
    if is_default? && is_default_changed?
      EasyPageTemplate.update_all(:is_default => false, :easy_pages_id => self.easy_pages_id)
    end
  end

  def template_modules(entity_id=nil, options={})
    if (tab = options[:tab])
      tab = tab.to_i
      tab = 1 if tab <= 0
    end
    scope = EasyPageTemplateModule.scoped(:include => [:zone_definition, :module_definition]).order('position ASC')
    table_name = EasyPageTemplateModule.table_name.to_sym
    scope = scope.where(table_name => {:easy_page_templates_id => self.id})

    scope = scope.where(table_name => {:entity_id => entity_id})

    scope = scope.where(table_name => {:tab => tab}) if tab

    page_template_modules = scope.all.group_by{|x| x.zone_definition.zone_name}

    self.page_definition.zones.each do |zone|
      page_template_modules[zone.zone_definition.zone_name] ||= []
    end

    page_template_modules
  end

  def template_tab_modules(page_tab, entity_id = nil)

    scope = EasyPageTemplateModule.scoped(:include => [:zone_definition, :module_definition]).order('position ASC')
    table_name = EasyPageTemplateModule.table_name.to_sym
    scope = scope.where(table_name => {:easy_page_templates_id => self.id})

    scope = scope.where(table_name => {:entity_id => entity_id})

    scope = scope.where(table_name => {:tab_id => page_tab})

    page_template_modules = scope.all.group_by{|x| x.zone_definition.zone_name}

    self.page_definition.zones.each do |zone|
      page_template_modules[zone.zone_definition.zone_name] ||= []
    end

    page_template_modules
  end

end


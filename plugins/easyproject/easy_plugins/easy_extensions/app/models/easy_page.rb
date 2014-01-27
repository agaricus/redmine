class EasyPage < ActiveRecord::Base
  self.table_name = 'easy_pages'

  has_many :zones, :class_name => "EasyPageAvailableZone", :foreign_key => 'easy_pages_id', :include => :zone_definition, :order => "#{EasyPageAvailableZone.table_name}.position ASC", :dependent => :destroy
  has_many :modules, :class_name => "EasyPageAvailableModule", :foreign_key => 'easy_pages_id', :include => :module_definition, :dependent => :destroy
  has_many :templates, :class_name => "EasyPageTemplate", :foreign_key => 'easy_pages_id', :dependent => :destroy

  has_many :all_modules, :through => :zones
  has_many :easy_page_tabs, :class_name => "EasyPageUserTab", :foreign_key => 'page_id', :dependent => :destroy

  validates_length_of :page_name, :in => 1..50, :allow_nil => false

  before_save :change_page_name

  @easy_pages = {}

  EasyPage.all.each do |page|
    src = <<-end_src
      def self.page_#{page.page_name.underscore}
        @easy_pages[#{page.id}] ||= EasyPage.find(#{page.id})
      end
    end_src
    class_eval src, __FILE__, __LINE__
  end if EasyPage.table_exists?

  def self.method_missing(m, *args, &block)
    if m.to_s.start_with?('page_') && page = EasyPage.where(:page_name => m.to_s[5..-1].dasherize).first
      return page
    else
      super
    end
  end

  def self.find_similiar(page_name)
    EasyPage.find(:all, :conditions => "#{EasyPage.table_name}.page_name like '#{page_name}-%'")
  end

  def user_modules(user = nil, entity_id = nil, tab = 1, options={})
    tab = tab.to_i
    tab = 1 if tab <= 0

    scope = EasyPageZoneModule.scoped(:include => [:zone_definition, :module_definition]).joins(:available_zone).readonly(false).order("#{EasyPageAvailableZone.table_name}.position ASC, #{EasyPageZoneModule.table_name}.position ASC")

    user = User.find(user) if (!user.nil? && !user.is_a?(User))

    if user.nil?
      scope = scope.where("#{EasyPageZoneModule.table_name}.user_id IS NULL")
    else
      scope = scope.where("#{EasyPageZoneModule.table_name}.user_id = #{user.id}")
    end
    if entity_id.nil?
      scope = scope.where("#{EasyPageZoneModule.table_name}.entity_id IS NULL")
    else
      scope = scope.where("#{EasyPageZoneModule.table_name}.entity_id = #{entity_id}")
    end
    scope = scope.where("#{EasyPageZoneModule.table_name}.easy_pages_id = #{self.id}")
    scope = scope.where("#{EasyPageZoneModule.table_name}.tab = #{tab}") unless options[:all_tabs]

    page_modules = scope.all.group_by{|x| x.zone_definition.zone_name}

    self.zones.each do |zone|
      page_modules[zone.zone_definition.zone_name] ||= []
    end

    page_modules
  end

  def user_tab_modules(tab, user = nil, entity_id = nil, options={})

    scope = EasyPageZoneModule.scoped(:include => [:zone_definition, :module_definition]).joins(:available_zone).readonly(false).order("#{EasyPageAvailableZone.table_name}.position ASC, #{EasyPageZoneModule.table_name}.position ASC")

    user = User.find(user) if (!user.nil? && !user.is_a?(User))

    if user.nil?
      scope = scope.where("#{EasyPageZoneModule.table_name}.user_id IS NULL")
    else
      scope = scope.where("#{EasyPageZoneModule.table_name}.user_id = #{user.id}")
    end
    if entity_id.nil?
      scope = scope.where("#{EasyPageZoneModule.table_name}.entity_id IS NULL")
    else
      scope = scope.where("#{EasyPageZoneModule.table_name}.entity_id = #{entity_id}")
    end
    if tab.nil?
      scope = scope.where("#{EasyPageZoneModule.table_name}.tab_id IS NULL")
    else
      scope = scope.where("#{EasyPageZoneModule.table_name}.tab_id = #{tab.id}")
    end
    scope = scope.where("#{EasyPageZoneModule.table_name}.easy_pages_id = #{self.id}")

    page_modules = scope.all.group_by{|x| x.zone_definition.zone_name}

    self.zones.each do |zone|
      page_modules[zone.zone_definition.zone_name] ||= []
    end

    page_modules
  end

  def translated_name
    l("easy_pages.pages.#{page_name.underscore}")
  end

  def translated_description
    l("easy_pages.pages_description.#{page_name.underscore}")
  end

  def unassigned_zones
    assigned_zones = self.zones.collect{|zone| zone.zone_definition.id}
    assigned_zones ||= []

    scope = EasyPageZone.scoped
    scope = scope.where("#{EasyPageZone.table_name}.id NOT IN (#{assigned_zones.join(',')})") if assigned_zones.size > 0

    scope.all
  end

  private

  def change_page_name
    self.page_name = self.page_name.gsub(/[ ]/, '-').dasherize unless self.page_name.nil?
  end

end


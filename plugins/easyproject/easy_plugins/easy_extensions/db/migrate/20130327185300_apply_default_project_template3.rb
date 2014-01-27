class ApplyDefaultProjectTemplate3 < ActiveRecord::Migration
  def self.up
    page = EasyPage.find_by_page_name('project-overview')
    page_template = EasyPageTemplate.default_template_for_page(page) if page
    if page && page_template && !EasyPageZoneModule.where("#{EasyPageZoneModule.table_name}.easy_pages_id = #{page.id}").exists?
      Project.all.each do |project|
        EasyPageZoneModule.create_from_page_template(page_template, nil, project.id)
      end
    end
  end

  def self.down
  end

end
class EasyXmlDataController < ApplicationController
  
  layout 'admin'
  
  before_filter :require_admin
  before_filter :check_exporter, :only => [:export_settings, :export]
  
  include ActionView::Helpers::TextHelper
  
  def export_settings
    @projects = Project.find(:all, :order => 'lft ASC')
    @exportables = EasyXmlData::Exporter.exportables
    @exportable_labels = EasyXmlData::Exporter.exportable_labels
  end
  
  def export
    params[:projects] ||= []
    params[:exportables] ||= []
    
    projects = []
    params[:projects].each do |project_id|
      project = Project.find(project_id.to_i)
      projects << project if project
    end
    
    exportables = EasyXmlData::Exporter.exportables.select{|exportable| params[:exportables].include?(exportable.to_s)}
    
    @exporter = EasyXmlData::Exporter.new(exportables, projects)
    archive_file = @exporter.build_archive
    respond_to do |format|
      format.api do
        send_file(archive_file, :filename => "export #{Time.now}.zip", :disposition => 'attachment')
      end
    end
  end
  
  def import_settings
    @mappables = %w(user role tracker issue_priority issue_status project_custom_field issue_custom_field document_category time_entry_activity)
  end
  
  def map
    importer = EasyXmlData::Importer.instance
    importer.add_map(params[:map], params[:mapping_entity_type])
    redirect_to :action => 'import'
  end
  
  def import
    importer = EasyXmlData::Importer.instance
    begin
      importer.archive_file = params[:archivefile].tempfile.path if params[:archivefile] && params[:archivefile].tempfile
    rescue Zip::ZipError => e
      flash[:error] = l(:label_import_zip_error)
      redirect_to :action => 'import_settings'
      return false
    end
    importer.auto_mappings = params[:auto_mappings] if params[:auto_mappings]
    importer.notifications = params[:notifications] == '1' if params[:notifications]
    begin
      p 'looking for mapping data'
      @mapping_entity_type, @mapping_entities, @existing_entities = importer.mapping_data
      pp @mapping_entity_type
      pp @mapping_entities
    end while !@mapping_entity_type.blank? && @mapping_entities.blank?
    unless @mapping_entity_type.blank?
      p 'mapping data found'
      render :action => 'entity_mapping'
    else
      importer.import
      validation_errors = []
      if validation_errors.any?
        flash[:error] = truncate(validation_errors.join('<br/>'), :length => 1000)
      else
        flash[:notice] = l(:label_import_success)
      end
      redirect_to :action => 'import_settings'
    end
  end
  
  private
  
  def check_exporter
    render_404 unless defined? EasyXmlData::Exporter
  end
  
end

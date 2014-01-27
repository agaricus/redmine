class EasyPublishingSettingsController < ApplicationController
  layout 'admin'

  menu_item :easy_publishing_settings

  before_filter :require_admin, :except => [:help_image]
  before_filter :easy_publishing_authentication, :except => [:help_image]
  before_filter :find_setting, :only => [:update, :destroy, :show, :edit, :help_image]

  helper :attachments
  include AttachmentsHelper

  def index
    @publishing_settings = EasyPublishingSetting.all
  end

  def new
    @publishing_setting = EasyPublishingSetting.new(:easy_publishing_module => EasyPublishingModule.first)
  end

  def create
    @publishing_setting = EasyPublishingSetting.new(params[:easy_publishing_setting])

    respond_to do |format|
      if @publishing_setting.save
        attachments = Attachment.attach_files(@publishing_setting, params[:attachments])
        @publishing_setting.reload
        invalid_attachments_names = @publishing_setting.validate_attachments
        if invalid_attachments_names.any?
          flash[:error] = l(:label_easy_publishing_invalid_file_type, :files => invalid_attachments_names.to_sentence)
        else
          flash[:notice] = l(:notice_successful_create)
        end
        format.html { redirect_to({:action => 'index'}) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def show
  end

  def edit
  end

  def update
    if @publishing_setting.update_attributes(params[:easy_publishing_setting])
      attachments = Attachment.attach_files(@publishing_setting, params[:attachments])
      @publishing_setting.reload
      invalid_attachments_names = @publishing_setting.validate_attachments
      if invalid_attachments_names.any?
        flash[:error] = l(:label_easy_publishing_invalid_file_type, :files => invalid_attachments_names.to_sentence)
      else
        flash[:notice] = l(:notice_successful_create)
      end
      redirect_to :action => 'index'
    else
      render :action => "edit"
    end
  end

  def destroy
    @publishing_setting.destroy
    respond_to do |format|
      format.html { redirect_to({:action => 'index'}) }
    end
  end

  def help_image
    att = @publishing_setting.attachments.first
    if att && File.exist?(att.diskfile)
      send_file(att.diskfile, :filename => filename_for_content_disposition(att.filename),
        :type => detect_content_type(att),
        :disposition => (att.image? ? 'inline' : 'attachment'))
    else
      render_404
    end
  end

  def dependent_fields
    if publishing_module = EasyPublishingModule.find_by_id(params[:easy_publishing_module_id])
      @publishing_setting = EasyPublishingSetting.new(:easy_publishing_module_id => publishing_module)
      render :partial => "dependent_fields_#{publishing_module.name}"
    else
      render :text => ''
    end
  end

private

  def find_setting
    @publishing_setting = EasyPublishingSetting.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def easy_publishing_authentication
    if !EasyPublishingSetting.editable?
      render_403
      return false
    end
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end

end

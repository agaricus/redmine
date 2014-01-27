class EasyAvatarsController < ApplicationController

  before_filter :find_entity, :except => [:show_avatar]

  helper :avatars
  include AvatarsHelper

  # def avatar
  # end



  def show
    file_name = params[:file_name]
    att = Attachment.where(:description => 'avatar', :disk_filename => file_name).select([:content_type, :disk_directory, :disk_filename]).first if file_name

    render_avatar_from_attachment(att)
  end

  # def show_entity_avatar
  #   entity_avatar_attachment = @entity.avatar

  #   render_avatar_from_attachment(@entity.avatar)
  # end

  def create
    unless params[:avatar].blank?
      file_field = params[:avatar]
      # clear current avatar
      @entity.avatar = nil
      @entity.save_attachments({'first' => {'file' => file_field, 'description' => 'avatar'}})
      @entity.attach_saved_attachments
      @entity.reload
      av = @entity.avatar
      @entity.update_attribute('easy_avatar', av.disk_filename.to_s)

      begin
        resize_image_to_fit(av.diskfile, 240, 320)
      rescue
      end

      if Object.const_defined?(:Magick)
        if !av.content_type.start_with?('image')
          flash[:error] = 'Invalid file type'
          redirect_to :back
        else
          render(:action => 'crop_avatar')
        end
      else
        redirect_back_or_default(:controller => 'my', :action => 'account')
      end
    else
      flash[:error] = l(:error_no_file_selected_to_upload)
      redirect_to :back
    end
  end

  def destroy
    @entity.avatar = nil
    @entity.update_attribute('easy_avatar', nil)
    respond_to do |format|
      format.js
    end
  end

  def crop_avatar
    av = @entity.avatar
    if !av
      redirect_to :back
    elsif !av.content_type.start_with?('image')
      @entity.avatar = nil
      flash[:error] = 'Invalid file type'
      redirect_to :back
    end
  end

  def save_avatar_crop
    crop(@entity)
    redirect_back_or_default({:controller => 'my', :action => 'account'})
  end

  private

  def find_entity
    if params[:entity_id] && params[:entity_type]
      @entity = params[:entity_type].classify.constantize.find(params[:entity_id])
    elsif params[:id]
      # Old way only for users
      @entity = User.find(params[:id])
    else
      # Old default
      @entity = User.current
    end
    render_404 if @entity.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def save_or_delete_avatar(user)
  end

  def render_avatar_from_attachment(entity_avatar_attachment)
    if entity_avatar_attachment
      content_type = entity_avatar_attachment.content_type
      image_file = entity_avatar_attachment.diskfile if File.exist?(entity_avatar_attachment.diskfile)
    end

    default_image_path = File.join(EasyExtensions::EASY_EXTENSIONS_DIR, 'assets', 'images', 'avatar.jpg')

    content_type ||= 'image/jpeg'
    image_file ||= default_image_path if File.exist?(default_image_path)

    unless image_file.blank?
      if stale?(:etag => image_file)
        send_file(image_file, :type => content_type, :disposition => 'inline')
      end
    else
      render :nothing => true
    end
  end

end

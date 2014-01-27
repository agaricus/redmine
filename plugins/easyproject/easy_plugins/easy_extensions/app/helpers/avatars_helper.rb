module AvatarsHelper

  def self.included(base)
    base.send(:include, ::RmagicHelper) if Object.const_defined?(:Magick)
    base.send(:include, ActionView::Helpers::AssetTagHelper) unless base.respond_to?(:image_path)
  end

  def resize_image(image_url, width, height)
  end

  def resize_image_to_fit(image_url, width, height)
  end

  def crop_image(image_url, c = {})
  end

  def crop(entity)
    crop_coordinates = {:x => params[:crop_x], :y => params[:crop_y], :height => params[:crop_height], :width => params[:crop_width]}
    crop_coordinates.each {|k,v| crop_coordinates[k] = v.to_i}
    a = entity.avatar
    crop_image(a.diskfile, crop_coordinates)
    resize_image(a.diskfile, 64, 64)
    a.description = 'avatar'
    a.save
    flash[:notice] = l(:message_avatar_uploaded)
  end

end

module RmagicHelper

  def resize_image(image_url, width, height)
    original_image = Magick::Image.read(image_url).first
    original_image.change_geometry("#{width}x#{height}") { |cols, rows, img|
      img.resize!(cols, rows)
      white_bg = Magick::Image.new(width, height)
      new_image = white_bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
      new_image.write(image_url)
    }

  end
  
  def resize_image_to_fit(image_url, width, height)
    original_image = Magick::Image.read(image_url).first
    original_image.change_geometry("#{width}x#{height}>") { |cols, rows, img|
      img.resize_to_fit!(cols, rows)
      original_image.write(image_url)
    }
  end
  
  def crop_image(image_url, c = {})
    img = Magick::Image.read(image_url).first
    img = img.crop(c[:x], c[:y], c[:width], c[:height], true)
    img.write(image_url)
  end
end

# You shall not include this helper elsewhere!
module EasyRatingInfoHelper
  
  def link_to_content_update(text, url_params = {}, html_options = {})
    url = url_for(url_params)
    link_to_function(
      text,
      "$(this).parents('.rating-infos').parent().load('#{url}')",
      html_options
    )
  end
  
end
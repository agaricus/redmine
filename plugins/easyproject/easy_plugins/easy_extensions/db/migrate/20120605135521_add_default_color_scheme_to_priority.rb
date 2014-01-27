class AddDefaultColorSchemeToPriority < ActiveRecord::Migration
  def change
    Enumeration.reset_column_information
    
    IssuePriority.active.each do |p|
      easy_color_scheme_value = case p.position
      when 1
        "scheme-#{4}"
      when 3
        "scheme-#{2}"
      when 4
        "scheme-#{0}"
      when 5
        "scheme-#{1}"
      end
      
      p.update_column( :easy_color_scheme, easy_color_scheme_value )
    end
  end
end

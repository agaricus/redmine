class EasyVersionCategory < Enumeration
  has_many :versions, :foreign_key => 'easy_version_category_id'
  
  OptionName = :enumeration_easy_version_cetegory

  def option_name
    OptionName
  end

  def objects_count
    versions.count
  end

  def transfer_relations(to)
    versions.update_all("easy_version_category_id = #{to.id}")
  end
end

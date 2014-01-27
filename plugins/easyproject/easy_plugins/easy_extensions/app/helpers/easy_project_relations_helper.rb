module EasyProjectRelationsHelper

  def collection_for_relation_type_select
    values = EasyProjectRelation::TYPES
    values.keys.sort{|x,y| values[x][:order] <=> values[y][:order]}.collect{|k| [l(values[k][:name]), k]}
  end

end
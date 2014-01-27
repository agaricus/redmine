class MigrateEasyQueryDateFiltersBug < ActiveRecord::Migration  
  
  def self.up
    EasyQuery.all.each do |easy_query|
      save_query = false
      easy_query.filters.each do |field_name, filter_options|
        if filter_options.key?(:period)
          filter_options[:values] = HashWithIndifferentAccess.new(:from => '', :to => '', :period => filter_options.delete(:period))
          save_query = true
        end
      end
      easy_query.save if save_query
    end
  end

  def self.down
  end

end

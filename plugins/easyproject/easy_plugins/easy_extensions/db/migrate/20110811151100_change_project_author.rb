class ChangeProjectAuthor < ActiveRecord::Migration
  def self.up
    author = User.active.where(:admin => true).first
    
    if author
      Project.update_all("author_id = #{author.id}", 'author_id IS NULL')
    end
  end

  def self.down
  end
end

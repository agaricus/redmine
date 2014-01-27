class FillNullProjectIdentifierAgain < ActiveRecord::Migration
  def self.up
    Project.update_all('identifier = id', 'identifier IS NULL')
  end

  def self.down
  end
end

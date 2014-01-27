class MigrateNewsUsers < ActiveRecord::Migration
  def self.up
    EasyUserReadEntity.connection.execute("INSERT INTO #{EasyUserReadEntity.table_name} (user_id, entity_type, entity_id, read_on) SELECT DISTINCT user_id, 'News', news_id, NOW() FROM news_users")
  end

  def self.down
  end
end

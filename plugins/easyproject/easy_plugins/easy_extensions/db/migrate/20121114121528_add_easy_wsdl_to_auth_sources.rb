class AddEasyWsdlToAuthSources < ActiveRecord::Migration
  def self.up
    add_column :auth_sources, :easy_wsdl, :string
  end

  def self.down
    remove_column :auth_sources, :easy_wsdl
  end
end
class AddTokenToAuthentication < ActiveRecord::Migration
  def self.up
    add_column :authentication, :token, :string
    add_column :authentication, :secret, :string
  end

  def self.down
    remove_column :authentication, :token
  end
end

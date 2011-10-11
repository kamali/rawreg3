class CreateAuthentication < ActiveRecord::Migration
  def self.up
    create_table :authentication do |t|
      t.integer :user_id
      t.string :provider
      t.string :uid

      t.timestamps
    end
    add_index :authentication, :user_id
    add_index :authentication, [:provider, :uid], :unique => true
  end

  def self.down
    drop_table :authentication
  end
end

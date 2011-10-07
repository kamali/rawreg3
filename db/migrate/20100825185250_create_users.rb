class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :user do |t|
      t.timestamps

      t.column :email, :string
      t.column :hashed_password, :string
      t.column :salt, :string
      t.column :verified, :boolean    ## whether my email address has been verified
      t.column :deactivated, :string  ## whether my account has been deactivated

      t.column :name, :string         ## OPTIONAL
      t.column :roles, :string        ## OPTIONAL. set to include "admin" for admin tools

      t.column :timezone, :string
    end

    ## make email unique in the db
    add_index :user, :email, :unique => true

  end

  def self.down
    drop_table :user
  end
end

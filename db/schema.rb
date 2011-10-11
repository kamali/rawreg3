# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111007173050) do

  create_table "authentication", :force => true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "uid"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "authentication", ["provider", "uid"], :name => "index_authentication_on_provider_and_uid", :unique => true
  add_index "authentication", ["user_id"], :name => "index_authentication_on_user_id"

  create_table "user", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "email"
    t.string   "hashed_password"
    t.string   "salt"
    t.boolean  "verified"
    t.string   "deactivated"
    t.string   "name"
    t.string   "roles"
    t.string   "timezone"
  end

  add_index "user", ["email"], :name => "index_user_on_email", :unique => true

end

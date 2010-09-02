# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20100828000244) do

  create_table "bookmarklet_keys", :force => true do |t|
    t.string   "value",      :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "links", :force => true do |t|
    t.text     "preview_html"
    t.string   "title",                          :null => false
    t.string   "url"
    t.boolean  "show_link",    :default => true, :null => false
    t.integer  "like_count",   :default => 0,    :null => false
    t.integer  "user_id",                        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.boolean  "is_god",               :default => false, :null => false
    t.boolean  "can_admin",            :default => false, :null => false
    t.boolean  "can_edit_raw_html",    :default => false, :null => false
    t.string   "facebook_id"
    t.string   "facebook_session_key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end

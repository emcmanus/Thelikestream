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

ActiveRecord::Schema.define(:version => 20100907123049) do

  create_table "bookmarklet_keys", :force => true do |t|
    t.string   "value",      :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "future_pages", :force => true do |t|
    t.string   "media_category"
    t.string   "thumbnail_small",        :default => ""
    t.integer  "thumbnail_small_width",  :default => 0
    t.integer  "thumbnail_small_height", :default => 0
    t.string   "thumbnail_full",         :default => ""
    t.integer  "thumbnail_full_width",   :default => 0
    t.integer  "thumbnail_full_height",  :default => 0
    t.text     "introduction"
    t.text     "html_body"
    t.string   "title",                  :default => ""
    t.string   "like_title",             :default => ""
    t.string   "source_url"
    t.string   "shortened_url",          :default => ""
    t.boolean  "show_link",              :default => true
    t.boolean  "is_cloaked",             :default => false
    t.integer  "like_count",             :default => 0
    t.integer  "weighted_score",         :default => 0
    t.string   "slug"
    t.integer  "user_id",                                   :null => false
    t.datetime "launch_threshold"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "page_votes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pages", :force => true do |t|
    t.string   "media_category"
    t.string   "thumbnail_small",        :default => ""
    t.integer  "thumbnail_small_width",  :default => 0
    t.integer  "thumbnail_small_height", :default => 0
    t.string   "thumbnail_full",         :default => ""
    t.integer  "thumbnail_full_width",   :default => 0
    t.integer  "thumbnail_full_height",  :default => 0
    t.text     "introduction"
    t.text     "html_body"
    t.string   "title",                  :default => ""
    t.string   "like_title",             :default => ""
    t.string   "source_url"
    t.string   "shortened_url",          :default => ""
    t.boolean  "show_link",              :default => true
    t.boolean  "is_cloaked",             :default => false
    t.integer  "like_count",             :default => 0
    t.integer  "weighted_score",         :default => 0
    t.integer  "user_id",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "slug"
  end

  create_table "users", :force => true do |t|
    t.boolean  "is_god",               :default => false, :null => false
    t.boolean  "can_admin",            :default => false, :null => false
    t.boolean  "can_edit_raw_html",    :default => false, :null => false
    t.string   "facebook_id"
    t.string   "facebook_session_key"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_puppet",            :default => false
  end

end

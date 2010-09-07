class CreateFuturePages < ActiveRecord::Migration
  def self.up
    create_table :future_pages do |t|
      
      # Copied from Schema
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
      
      t.references  :user, :null => false
      
      # When to launch
      t.datetime  "launch_threshold"
      
      t.timestamps
    end
  end

  def self.down
    drop_table :future_pages
  end
end

# t.string   "media_category"
# t.string   "thumbnail_small",        :default => ""
# t.integer  "thumbnail_small_width",  :default => 0
# t.integer  "thumbnail_small_height", :default => 0
# t.string   "thumbnail_full",         :default => ""
# t.integer  "thumbnail_full_width",   :default => 0
# t.integer  "thumbnail_full_height",  :default => 0
# t.text     "introduction"
# t.text     "html_body"
# t.string   "title",                  :default => ""
# t.string   "like_title",             :default => ""
# t.string   "source_url"
# t.string   "shortened_url",          :default => ""
# t.boolean  "show_link",              :default => true
# t.boolean  "is_cloaked",             :default => false
# t.integer  "like_count",             :default => 0
# t.integer  "weighted_score",         :default => 0
# t.string   "slug"
# t.integer  "user_id",                                   :null => false
# t.datetime "launch_threshold"
# t.datetime "created_at"
# t.datetime "updated_at"

class FuturePageQueueController < ApplicationController

  before_filter :require_admin, :except=>[:tick]

  def index
    @pages = Page.find(:all, :conditions=>["queue_for_later_submission=1"], :order=>["updated_at"])
  end


  def tick

    # Rate-limit submissions, use rand to appear less automated
    n = Time.now

    if n.hour >= 23
      # 11pm+
      lotto = (rand(12)==0)
    elsif n.hour >= 19
      # 7pm+
      lotto = (rand(8)==0)
    elsif n.hour >= 8
      # 8am+
      lotto = (rand(3)==0)
    else
      # midnight-8am
      lotto = (rand(12)==0)
    end

    if lotto
      @page = Page.find(:first, :conditions=>["queue_for_later_submission=1"], :order=>["updated_at"])
      if @page.nil?
        render :text=>"nothing to submit" and return
      end
      @page.queue_for_later_submission = false
      @page.show_in_popular = true
      @page.like_count_boost = [2, rand(6)+1].max # 2-6 points
      submit_time = rand(15).minutes.ago
      @page.created_at = submit_time
      @page.updated_at = submit_time
      @page.update_like_count_with_url page_path(@page, :only_path=>false)
      if @page.save
        render :text=>"success" and return
      else
        render :text=>"couldn't save" and return
      end
    else
      render :text=>"lost the lotto" and return
    end
  end

end

class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      
      t.string      :media_category                               # Image, video, link, quiz, quotes, other
      
      # Small thumb
      t.string      :thumbnail_small, :default => ""
      t.integer     :thumbnail_small_width,   :default => 0
      t.integer     :thumbnail_small_height,  :default => 0
      
      # Normal thumb
      t.string      :thumbnail_full,  :default => ""
      t.integer     :thumbnail_full_width,  :default => 0
      t.integer     :thumbnail_full_height, :default => 0
      
      t.text        :introduction,    :default => ""              # Plain text!
      t.text        :html_body,       :default => ""              # HTML
      
      t.string      :title,           :default => ""                                        
      t.string      :like_title,      :default => ""              # for og:title
      
      t.string      :source_url,      :defautl => ""
      t.string      :shortened_url,   :default => ""
      t.boolean     :show_link,       :default => true            # whether to link back to the source
      
      t.boolean     :is_cloaked,      :default => false           # cloak link, use aggressive <OG:> tags
      
      t.integer     :like_count,      :default => 0
      t.integer     :weighted_score,  :default => 0               # Ts + 45000*log(like_count)
      
      t.references  :user,            :null => false
      
      t.timestamps
    end
  end

  def self.down
    # drop_table :pages
  end
end

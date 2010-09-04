class CreatePages < ActiveRecord::Migration
  def self.up
    create_table :pages do |t|
      
      t.string      :media_category                               # Image, video, link, quiz, quotes, other
                                                                  
      t.string      :thumbnail_small                              
      t.string      :thumbnail_full                               
                                                                  
      t.text        :introduction                                 # Plain text!
      t.text        :html_body                                    # HTML
                                                                  
      t.string      :title                                        
      t.string      :like_title                                   # for og:title
      
      t.string      :source_url
      t.string      :shortened_url
      t.boolean     :show_link,       :default => true            # whether to link back to the source
      
      t.boolean     :is_cloaked,      :default => false           # cloak link, use aggressive <OG:> tags
      
      t.integer     :like_count,      :default => 0
      t.integer     :weighted_score                               # Ts + 45000*log(like_count)
      
      t.references  :user
      
      t.timestamps
    end
  end

  def self.down
    # drop_table :pages
  end
end

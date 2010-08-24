class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      
      t.text        :preview_html                                               # Optional if show_link == true
      t.string      :title,             :null => false
      t.string      :url                                                        # Optional if show_link == false
      t.boolean     :show_link,         :null => false,     :default => true    # No if this is empty content
      t.integer     :like_count,        :null => false,     :default => 0
      
      t.references  :user,              :null => false
      t.timestamps      
    end
  end

  def self.down
    drop_table :links
  end
end

class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.text :description
      t.string :title
      t.text :embed_code
      t.integer :like_count

      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end

class CreateLinks < ActiveRecord::Migration
  def self.up
    create_table :links do |t|
      t.text :preview
      t.string :title
      t.string :url
      t.integer :like_count

      t.timestamps
    end
  end

  def self.down
    drop_table :links
  end
end

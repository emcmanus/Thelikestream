class CreatePictures < ActiveRecord::Migration
  def self.up
    create_table :pictures do |t|
      t.text :description
      t.string :title
      t.string :full_path
      t.integer :like_count

      t.timestamps
    end
  end

  def self.down
    drop_table :pictures
  end
end

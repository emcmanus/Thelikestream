class CreateJokes < ActiveRecord::Migration
  def self.up
    create_table :jokes do |t|
      t.string :title
      t.text :body
      t.integer :like_count

      t.timestamps
    end
  end

  def self.down
    drop_table :jokes
  end
end

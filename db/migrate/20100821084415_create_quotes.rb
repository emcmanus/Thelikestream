class CreateQuotes < ActiveRecord::Migration
  def self.up
    create_table :quotes do |t|
      t.string :title
      t.integer :like_count

      t.timestamps
    end
  end

  def self.down
    drop_table :quotes
  end
end

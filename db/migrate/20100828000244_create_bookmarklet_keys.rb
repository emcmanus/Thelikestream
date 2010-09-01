class CreateBookmarkletKeys < ActiveRecord::Migration
  def self.up
    create_table :bookmarklet_keys do |t|
      t.string        :value,     :null=>false
      t.references    :user,      :null=>false
      
      t.timestamps
      
      t.create_index :value
    end
  end

  def self.down
    drop_table :bookmarklet_keys
  end
end

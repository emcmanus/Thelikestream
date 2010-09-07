class CreatePageVotes < ActiveRecord::Migration
  def self.up
    create_table :page_votes do |t|
      t.references :user
      t.references :page
      
      t.timestamps
    end
  end

  def self.down
    drop_table :page_votes
  end
end

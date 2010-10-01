class AddLikeCountBoostToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :like_count_boost, :integer, :default => 0
  end

  def self.down
    remove_column :pages, :like_count_boost
  end
end

class AddCommunityAndMusicCategoriesToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :show_in_category_community, :boolean
    add_column :pages, :show_in_category_music, :boolean
  end

  def self.down
    remove_column :pages, :show_in_category_community
    remove_column :pages, :show_in_category_music
  end
end

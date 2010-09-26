class AddQualityFlagsToPage < ActiveRecord::Migration
  def self.up
    # Show in favorites
    add_column :pages, :show_in_favorites, :boolean, :default => false
    # Display in Popular
    add_column :pages, :show_in_popular, :boolean, :default => false
    # Page.update_all('show_in_popular=false, show_in_favorites=false')
  end

  def self.down
    remove_column :pages, :show_in_favorites
    remove_column :pages, :show_in_popular
  end
end

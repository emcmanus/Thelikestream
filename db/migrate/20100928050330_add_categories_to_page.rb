class AddCategoriesToPage < ActiveRecord::Migration
  def self.up
    # Categories:
    # Breaking Tech - TMZ type content
    # Gossip - TMZ type stuff
    # Gaming
    # Smart
    # Funny
    # Other
    add_column :pages, :show_in_category_breaking_tech, :boolean, :default=>false
    add_column :pages, :show_in_category_gossip,        :boolean, :default=>false
    add_column :pages, :show_in_category_gaming,        :boolean, :default=>false
    add_column :pages, :show_in_category_smart,         :boolean, :default=>false
    add_column :pages, :show_in_category_funny,         :boolean, :default=>false
    add_column :pages, :show_in_category_other,         :boolean, :default=>false
  end

  def self.down
    remove_column :pages, :show_in_category_breaking_tech
    remove_column :pages, :show_in_cagegory_gossip
    remove_column :pages, :show_in_category_gaming
    remove_column :pages, :show_in_category_smart
    remove_column :pages, :show_in_category_funny
    remove_column :pages, :show_in_category_other
  end
end

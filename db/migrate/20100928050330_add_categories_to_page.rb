class AddCategoriesToPage < ActiveRecord::Migration
  def self.up
    # Categories:
    # Breaking Tech - TMZ type content
    # Gossip - TMZ type stuff
    # Gaming
    # Smart
    # Funny
    # Other
    add_column :pages, :show_in_category_breaking_tech, :boolean
    add_column :pages, :show_in_category_gossip,        :boolean
    add_column :pages, :show_in_category_gaming,        :boolean
    add_column :pages, :show_in_category_smart,         :boolean
    add_column :pages, :show_in_category_funny,         :boolean
    add_column :pages, :show_in_category_other,         :boolean
  end

  def self.down
  end
end

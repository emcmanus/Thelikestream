class AddScrapedFieldToPages < ActiveRecord::Migration
  def self.up
    add_column  :pages, :remote_url_scraped, :boolean, :default => false
  end

  def self.down
    remove_column  :pages, :remote_url_scraped
  end
end

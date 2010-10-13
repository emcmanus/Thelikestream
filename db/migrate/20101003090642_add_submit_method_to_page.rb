class AddSubmitMethodToPage < ActiveRecord::Migration
  def self.up
    add_column :pages, :created_with_bookmark, :boolean, :default => false
    add_column :pages, :created_with_site_form, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :created_with_bookmark
    remove_column :pages, :created_with_site_form
  end
end

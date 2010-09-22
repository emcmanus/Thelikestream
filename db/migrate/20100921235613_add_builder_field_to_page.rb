class AddBuilderFieldToPage < ActiveRecord::Migration
  def self.up
    add_column  :pages, :created_with_builder, :boolean, :default => false
  end

  def self.down
    remove_column  :pages, :created_with_builder
  end
end

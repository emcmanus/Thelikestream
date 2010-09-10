class AddProcessedFieldToPages < ActiveRecord::Migration
  def self.up
    add_column  :pages, :image_processing_started,  :boolean, :default => false
    add_column  :pages, :image_processing_finished, :boolean, :default => false
  end

  def self.down
    remove_column :pages, :image_processing_started
    remove_column :pages, :image_processing_finished
  end
end

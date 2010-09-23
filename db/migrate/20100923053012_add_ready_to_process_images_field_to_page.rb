class AddReadyToProcessImagesFieldToPage < ActiveRecord::Migration
  def self.up
    add_column  :pages, :ready_to_process_images, :boolean, :default => false
    Page.update_all ["ready_to_process_images = ?", true]
  end
  
  def self.down
    remove_column  :pages, :ready_to_process_images
  end
end

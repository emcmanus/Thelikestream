class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      
      t.boolean :is_god,            :null => false,   :default => false
      t.boolean :can_admin,         :null => false,   :default => false
      t.boolean :can_edit_raw_html, :null => false,   :default => false
      
      t.string  :facebook_id
      t.string  :facebook_session_key      # When does this get used?
      
      # Other cacehed fields?
      # ...
      
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end

class AddSubmitLaterFlag < ActiveRecord::Migration
  def self.up
    add_column :pages, :queue_for_later_submission, :boolean
  end

  def self.down
    remove_column :pages, :queue_for_later_submission
  end
end

class PageVote < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :page
  
  validates_associated      :user
  validates_associated      :page
end

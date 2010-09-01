class BookmarkletKey < ActiveRecord::Base
  belongs_to :user
  
  validates_associated      :user
  validates_presence_of     :user
  
  validates_presence_of     :value
  validates_uniqueness_of   :value
  validates_length_of       :value,           :is => 20  
end

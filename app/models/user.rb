# t.boolean  "is_god",               :default => false, :null => false
# t.boolean  "can_admin",            :default => false, :null => false
# t.boolean  "can_edit_raw_html",    :default => false, :null => false
# t.string   "facebook_id"
# t.string   "facebook_session_key"
# t.datetime "created_at"
# t.datetime "updated_at"
# t.boolean  "is_puppet",            :default => false

class User < ActiveRecord::Base
  
  has_many :page_votes
  has_many :pages
  has_many :bookmarklet_keys
  
  validates_presence_of   :facebook_id
  validates_uniqueness_of :facebook_id
  
  # Bools
  validates_inclusion_of   :is_god, :in => [true, false]
  validates_inclusion_of   :can_admin, :in => [true, false]
  validates_inclusion_of   :can_edit_raw_html, :in => [true, false]
  
  # Lookup of permissions -> editable attributes
  EDIT_PERMISSIONS = {
    :god => %w[is_god can_admin can_edit_raw_html facebook_id facebook_session_key created_at updated_at is_puppet],
    :admin => %w[can_edit_raw_html facebook_id is_puppet],
    :editor => %w[],
    :owner => %w[]
  }
  
  def self.create_from_validated_id(validated_id)
    return if validated_id.blank?
    
    begin
      user = self.new
      user.facebook_id = validated_id
      
      # Admin Privleges
      user.is_god = false
      user.can_admin = false
      user.can_edit_raw_html = false
      
      return user if user.save
    rescue ActiveRecord::RecordInvalid => e
      logger.info "in rescue branch"
      logger.error e.record.errors.full_messages.to_sentence
    end
  end
  
  
  # Privileges
  
  def is_admin
    return true if self.is_god or self.can_admin
  end
  
  def is_content_editor
    return true if self.is_god or self.can_admin or self.can_edit_raw_html
  end
  

  # Convenience Methods

  def recent_votes
    @recent_votes = PageVote.find_by_user_id(self.id, :limit=>5, :order=>"created_at DESC") || []
  end

  def recent_submissions
    @recent_submissions = Page.find(:all, :limit=>15, :order=>"created_at DESC", :conditions=>["user_id=?", self.id]) || []
  end

  def popular_badges
    @popular_badges = Page.find(:all, :limit=>11, :order=>"created_at DESC", :conditions=>['show_in_popular = 1 and user_id=?', self.id]) || []
  end

  # Story's submitted by this user marked as favorite
  def favorite_badges
    @favorite_badges = Page.find(:all, :limit=>11, :order=>"created_at DESC", :conditions=>['show_in_favorites = 1 and user_id=?', self.id]) || []
  end

end

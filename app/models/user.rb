class User < ActiveRecord::Base
  
  has_many :links
  has_many :bookmarklet_keys
  
  validates_presence_of   :facebook_id
  validates_uniqueness_of :facebook_id
  
  # Bools
  validates_inclusion_of   :is_god, :in => [true, false]
  validates_inclusion_of   :can_admin, :in => [true, false]
  validates_inclusion_of   :can_edit_raw_html, :in => [true, false]
  
  
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
  
end
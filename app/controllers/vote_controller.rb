require 'uri/http'

class VoteController < ApplicationController
  
  def vote_for_url
    # Check for user
    # Check for existing vote
    # If user, and no existing vote, create and persist Like object
    
    # Whether to increment the HTML "like counter"
    @increment_counter = false
    
    # Attempt to parse URL and recognize the path
    begin
      vote_uri = URI.parse params[:vote]
      path_to_parse = vote_uri.path
      unless vote_uri.query.blank?
        path_to_parse += "?#{vote_uri.query}"
      end
      recognized_path = ActionController::Routing::Routes.recognize_path(path_to_parse)
    rescue
      logger.error $!
    end
    
    if recognized_path && recognized_path[:controller] == "page"
      @record_receiving_vote = Page.find recognized_path[:id]
      
      if current_user && current_user.is_content_editor && params[:boost]
        # BOOST Score
        @record_receiving_vote.increment! :like_count
        @record_receiving_vote.calculate_weighted_score!
        @increment_counter = true
      elsif current_user && @record_receiving_vote
        # Check to see if this user has already voted
        vote = PageVote.find_by_user_id_and_page_id(current_user.id, @record_receiving_vote.id)
        if vote.nil?
          # user has not already voted for this page
          vote = PageVote.new :user=>current_user, :page=>@record_receiving_vote
          if vote.save
            @record_receiving_vote.increment! :like_count
            @record_receiving_vote.calculate_weighted_score!
          end
          @increment_counter = true
        end
      elsif current_user.nil? && @record_receiving_vote
        # Still increment for anonymous users
        @increment_counter = true
      end
    end
    
    if @record_receiving_vote
      @page_id = recognized_path[:id].to_i
    end
    
    # Render result JSON
    render :content_type => "text/javascript", :layout => false
  end
  
end

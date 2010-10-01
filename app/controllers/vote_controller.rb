require 'uri/http'

class VoteController < ApplicationController

  before_filter :require_content_editor, :only=>[:boost_page]
  
  def boost_score
    page = Page.find(params[:id])
    unless page.increment! :like_count_boost
      logger.error "Unable to increment page id: #{params[:id]}"
    end
    render :text => "void(0)"
  end
  
  def vote_square_roll_out
    page = Page.find params[:id]
    page.update_like_count_with_url page_path(page, :only_path=>false)
    page.save
    render :text => (page.adjusted_like_count.to_s || "0")
  end

  def vote_for_url
    # Attempt to parse URL and recognize the page object
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

      if current_user && @record_receiving_vote
        # Log vote
        vote = PageVote.find_or_create_by_user_id_and_page_id(current_user.id, @record_receiving_vote.id)
      end

      # Don't worry about updating the like count, we'll do that on roll-out
    end

    # Render result JSON
    render :content_type => "text/javascript", :layout => false
  end

end

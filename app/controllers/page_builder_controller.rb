class PageBuilderController < ApplicationController

  before_filter   :require_user

  def new
    # Turn the user's form into a valid Page
  end

  def create
    redirect_to root_path and return unless current_user

    if params[:is_draft].to_i == 1 or !params[:page_id].blank?
      if params[:page_id].blank?
        # If the user hits save draft before submitting
        page = Page.new
      else
        page = Page.find params[:page_id]
        unless page and (page.user == current_user or current_user.is_admin)
          flash[:notice] = "You don't have permission to update this page."
          redirect_to root_path and return
        end
      end
    else
      page = Page.new
    end

    # Check for admin fields
    if current_user.is_content_editor
      if params[:show_in_popular] == "on"
        page.show_in_popular = true
      else
        page.show_in_popular = false
      end
      if params[:queue_for_later_submission]
        page.queue_for_later_submission = true
      else
        page.queue_for_later_submission = false
      end
      if params[:show_in_favorites] == "on"
        page.show_in_favorites = true
      else
        page.show_in_favorites = false
      end
    end

    page.user = current_user
    page.title = params[:title]
    page.sanitize_user_html params[:html_body]

    if params[:is_draft].to_i == 1
      page.ready_to_process_images = false
      page.save!
      flash[:notice] = "Draft saved"
      redirect_to page_builder_edit_path(page) and return
    else
      page.ready_to_process_images = true
      page.save!
      flash[:notice] = "Submitted!"
      #####
      redirect_to page_path(page) and return
      #redirect_to assign_category_path(page) and return
    end

  rescue ActiveRecord::RecordInvalid => e
    @page = e.record
    flash[:error] = @page.errors.full_messages.to_sentence
    render :action=>:new
  end

  def edit
    @page = Page.find params[:id]
  end

  def image_upload_form

    # Return a policy file with an object key we know to be unique
    # We do this for each new file, to ensure we don't overwrite an existing object on S3

    if current_user.nil? or current_user.id.nil?
      render :text=>"you must log in." and return
    end

    bucket            = S3Keys::S3Config.bucket
    access_key_id     = S3Keys::S3Config.access_key_id
    secret_access_key = S3Keys::S3Config.secret_access_key

    # Use the user's session key to generate the S3 object key
    expiration_date = 10.hours.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    unique_key      = SecureRandom.hex(10)
    acl             = 'public-read'
    max_filesize    = 25.megabyte

    # policy fields
    file_key = "builder_uploads/#{unique_key}"

    policy = Base64.encode64(
      "{'expiration': '#{expiration_date}',
        'conditions': [
          {'bucket': '#{bucket}'},
          {'key': '#{file_key}'},
          {'acl': '#{acl}'},
          {'success_action_status': '201'},
          ['content-length-range', 0, #{max_filesize}]
        ]
      }").gsub(/\n|\r/, '')

      signature = Base64.encode64(
        OpenSSL::HMAC.digest(
          OpenSSL::Digest::Digest.new('sha1'),
          secret_access_key, policy)).gsub("\n","")

          # View vars
          @access_key = access_key_id
          @form_action = "http://#{bucket}.s3.amazonaws.com/"
          @full_object_path = "http://#{bucket}.s3.amazonaws.com/#{file_key}"
          @bucket = bucket
          @file_key = file_key
          @policy = policy
          @signature = signature
          @success_action_status = "201"

          render :layout=>false
  end

end

class SignUpController < ApplicationController

  def create
    musician_params = params[:musician]
    access_token = musician_params[:access_token]
    refresh_token = musician_params[:refresh_token]
    calendar_ids = musician_params[:calendar_ids].reject { |x| x.blank? }
    email = musician_params[:email]
    found_emails = Musician.where("email = '#{email}'").count
    if found_emails == 0 && !access_token.blank? && !refresh_token.blank? && !calendar_ids.blank?
      musician = Musician.new(
        name: musician_params[:name],
        email: email,
        phone_number: musician_params[:phone_number],
        primary_instrument: musician_params[:primary_instrument],
        access_token: access_token,
        refresh_token: refresh_token,
        calendar_ids: calendar_ids
      )
      musician.save!
    #   booking = Booking.new
    #   booking.chosen_musicians = [@musician.id]
    #   booking.completed_at = Time.now
    #   booking.save!
    elsif access_token.blank? || refresh_token.blank?
      redirect_to controller: "sign_up", action: "index", flash: "Error validating email. Please try again."
    elsif found_emails > 0
      redirect_to controller: "sign_up", action: "index", flash: "Email already exsists. Please sign up with a different email."
    elsif calendar_ids.blank?
      redirect_to controller: "sign_up", action: "index", flash: "Please select at least 1 calendar to track."
    end
  end

  def index
    @primary_instruments = [
      { id: "bass", value: "Bass" },
      { id: "drums", value: "Drums" },
      { id: "guitar", value: "Guitar" },
      { id: "vocals", value: "Vocals" },
      { id: "other", value: "Other" },
    ]
    @redirect_uri = "http://54.205.235.245.54.205.235.245.xip.io/workflow/sign_up"
    @client_id = "621760050683-as0aceoats9oouvtbqbsvk55aobu3gt6.apps.googleusercontent.com"
    @client_secret = "nPxCjK7KxzIUZGFojl4qiQkd"
    @base_url = request.params
    if @base_url.key?("code")
      @code = @base_url[:code]
      @http_client = HTTPClient.new
      get_access_tokens
      get_user_email
      get_calendars
    end
  end

  def get_access_tokens
    body = {
      "redirect_uri": @redirect_uri,
      "client_id": @client_id,
      "client_secret": @client_secret,
      "code": @code,
      "grant_type": "authorization_code"
    }
    response = @http_client.post("https://accounts.google.com/o/oauth2/token", body)
    response_json = JSON.parse(response.body)
    @access_token = response_json["access_token"]
    @refresh_token = response_json["refresh_token"]
  end

  def get_user_email
    response = @http_client.get("https://www.googleapis.com/gmail/v1/users/me/profile?access_token=#{@access_token}")
    response_json = JSON.parse(response.body)
    @user_email = response_json["emailAddress"]
  end

  def get_calendars
    response = @http_client.get("https://www.googleapis.com/calendar/v3/users/me/calendarList?access_token=#{@access_token}")
    response_json = JSON.parse(response.body)
    @calendars = response_json["items"]
  end


end

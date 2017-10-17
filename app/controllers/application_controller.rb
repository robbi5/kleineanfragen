class ApplicationController < ActionController::Base
  # kleineAnfragen is sessionless. only "risky" form is for email subscription, and thats requiring double-opt-in.
  # So the following line is commented out:
  # protect_from_forgery with: :null_session

  # make request_id available to lograge
  # see other part in config/application.rb
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
  end

  # FIXME: correct place?
  def mime_extension(mime_type)
    case mime_type
    when Mime[:html]
      ''
    when Mime[:pdf]
      'pdf'
    when Mime[:txt]
      'txt'
    when Mime[:json]
      'json'
    else
      ''
    end
  end
end

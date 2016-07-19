class ApplicationController < ActionController::Base
  # kleineAnfragen is sessionless. only "risky" form is for email subscription, and thats requiring double-opt-in.
  # So the following line is commented out:
  # protect_from_forgery with: :null_session

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

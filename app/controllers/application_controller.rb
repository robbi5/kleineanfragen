class ApplicationController < ActionController::Base
  # kleineAnfragen is sessionless. only "risky" form is for email subscription, and thats requiring double-opt-in.
  protect_from_forgery with: :null_session

  # FIXME: correct place?
  def mime_extension(mime_type)
    case mime_type
    when Mime::HTML
      ''
    when Mime::PDF
      'pdf'
    when Mime::TXT
      'txt'
    else
      ''
    end
  end
end

class ApplicationMailer < ActionMailer::Base
  # default from: Rails.configuration.x.email_from # see config/application.rb
  layout 'mailer'

  helper do
    def display_obituary?
      Rails.application.config.x.display_obituary
    end
  end
end
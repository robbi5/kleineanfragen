class ApplicationMailer < ActionMailer::Base
  # default from: Rails.configuration.x.email_from # see config/application.rb
  layout 'mailer'
end

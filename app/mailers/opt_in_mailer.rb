class OptInMailer < ApplicationMailer
  def opt_in(opt_in, subscription)
    @opt_in = opt_in
    @subscription = subscription
    mail subject: 'kleineAnfragen - E-Mail-Adresse bestätigen', to: @opt_in.email
  end

  def report(opt_in, report)
    @opt_in = opt_in
    @report = report
    mail subject: '[report] #{@opt_in.email} ist nun auf der E-Mail-Blacklist', to: Rails.configuration.x.email_support
  end
end
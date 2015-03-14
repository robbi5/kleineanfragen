# Preview all emails at http://localhost:5000/rails/mailers/opt_in_mailer
class OptInMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:5000/rails/mailers/opt_in_mailer/opt_in
  def opt_in
    opt_in = OptIn.new(email: 'test@example.org')
    opt_in.assign_confirmation_token
    subscription = Subscription.new(id: 0, subtype: :body, query: 'BY')
    OptInMailer.opt_in(opt_in, subscription)
  end

  # Preview this email at http://localhost:5000/rails/mailers/opt_in_mailer/report
  def report
    opt_in = OptIn.new(email: 'test@example.org')
    report = Report.new(Time.now, '127.0.0.1', 'Example/1.0 UserAgent')
    OptInMailer.report(opt_in, report)
  end
end

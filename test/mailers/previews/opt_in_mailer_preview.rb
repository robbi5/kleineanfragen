# Preview all emails at http://localhost:5000/rails/mailers/opt_in_mailer
class OptInMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:5000/rails/mailers/opt_in_mailer/opt_in
  def opt_in
    opt_in = OptIn.new
    subscription = Subscription.new
    OptInMailer.opt_in(opt_in, subscription)
  end

  # Preview this email at http://localhost:5000/rails/mailers/opt_in_mailer/report
  def report
    opt_in = OptIn.new
    report = Report.new
    OptInMailer.report(opt_in, report)
  end
end

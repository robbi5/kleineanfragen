# Preview all emails at http://localhost:3000/rails/mailers/opt_in_mailer
class OptInMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/opt_in_mailer/opt_in
  def opt_in
    OptInMailer.opt_in
  end

  # Preview this email at http://localhost:3000/rails/mailers/opt_in_mailer/report
  def report
    OptInMailer.report
  end

end

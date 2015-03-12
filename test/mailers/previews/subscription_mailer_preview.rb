# Preview all emails at http://localhost:3000/rails/mailers/subscription_mailer
class SubscriptionMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/subscription_mailer/papers
  def papers
    subscription = Subscription.new(id: 0, subtype: :body, query: 'BY')
    papers = Paper.where(body: Body.find_by_state('BY')).limit(10).order(created_at: :desc).all
    SubscriptionMailer.papers(subscription, papers)
  end
end

class SendBodySubscriptionsJob < ApplicationJob
  queue_as :subscription

  def perform(body)
    Subscription.body.where(active: true, query: body.state).find_each do |sub|
      # using updated_at, because activation could be delayed by opt_in confirmation
      last_sent_at = sub.last_sent_at || sub.updated_at
      # use both, because some papers already exist, but are later answered and published
      papers = body.papers.where(['created_at > ? OR published_at > ?', last_sent_at, last_sent_at]).pluck(:id)
      next if papers.empty?
      # triggers ActionMailers DeliveryJob, see queue :mailer
      SubscriptionMailer.papers(sub, papers).deliver_later
    end
  end
end
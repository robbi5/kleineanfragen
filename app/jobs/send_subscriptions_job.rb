class SendSubscriptionsJob < ActiveJob::Base
  queue_as :subscription

  def perform(body)
    Subscription.where(active: true, subtype: 'body', query: body.state).find_each do |sub|
      # using updated_at, because activation could be delayed by opt_in confirmation
      last_sent_at = sub.last_sent_at || sub.updated_at
      papers = body.papers.where(['created_at > ?', last_sent_at]).pluck(:id)
      next if papers.empty?
      # triggers ActionMailers DeliveryJob, see queue :mailer
      SubscriptionMailer.papers(sub, papers).deliver_later
    end
  end
end
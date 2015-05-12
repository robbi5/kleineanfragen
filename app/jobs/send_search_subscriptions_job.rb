class SendSearchSubscriptionsJob < ActiveJob::Base
  queue_as :subscription

  def perform
    last_update = Paper.order(created_at: :desc).limit(1).first.created_at
    Subscription.search.where(active: true).where(['last_sent_at < ?', last_update]).find_each do |sub|
      # using updated_at, because activation could be delayed by opt_in confirmation
      last_sent_at = sub.last_sent_at || sub.updated_at

      search = SearchController.parse_query(sub.query)
      search.conditions[:created_at] = { gt: last_sent_at }

      # don't load the papers here, simply get the ids
      papers = SearchController.search_papers(search.term, search.conditions, load: false).map(&:id).map(&:to_i)
      next if papers.empty?

      # triggers ActionMailers DeliveryJob, see queue :mailer
      SubscriptionMailer.papers(sub, papers).deliver_later
    end
  end
end
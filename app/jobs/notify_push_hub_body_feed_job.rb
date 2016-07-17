class NotifyPuSHHubBodyFeedJob < ApplicationJob
  include ActiveJob::Retry.new(strategy: :variable,
                               delays: [5, 15, 30, 90],
                               retryable_exceptions: [Excon::Errors::Timeout])

  queue_as :subscription

  def perform(body)
    return if Rails.configuration.x.push_hub.blank?

    feed_url = Rails.application.routes.url_helpers.body_feed_url(body: body, format: :atom)
    urls = [feed_url, "#{feed_url}?feedformat=twitter"]

    urls.each do |url|
      success = self.class.notify(url)
      fail "Couldn't notify push hub for url \"#{url}\"" unless success
    end
  end

  def self.notify(feed_url)
    return false if Rails.configuration.x.push_hub.blank?

    response = Excon.post(
      Rails.configuration.x.push_hub,
      body: URI.encode_www_form(
        'hub.mode' => 'publish',
        'hub.url' => feed_url
      ),
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    [200, 204].include?(response.status)
  end
end
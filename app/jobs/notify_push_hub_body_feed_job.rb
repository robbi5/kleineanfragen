class NotifyPuSHHubBodyFeedJob < ApplicationJob
  queue_as :subscription

  def perform(body)
    return if Rails.configuration.x.push_hubs.blank?

    feed_url = Rails.application.routes.url_helpers.body_feed_url(body: body, format: :atom)
    urls = [feed_url, "#{feed_url}?feedformat=twitter"]

    hubs = Rails.configuration.x.push_hubs

    urls.each do |url|
      hubs.each do |hub|
        success = self.class.notify(hub, url)
        fail "Couldn't notify push hub \"#{hub}\" for url \"#{url}\"" unless success
      end
    end
  end

  def self.notify(hub, feed_url)
    return false if hub.blank?

    response = Excon.post(
      hub,
      body: URI.encode_www_form(
        'hub.mode' => 'publish',
        'hub.url' => feed_url
      ),
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    )

    [200, 204].include?(response.status)
  end
end
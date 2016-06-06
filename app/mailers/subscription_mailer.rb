class SubscriptionMailer < ApplicationMailer
  helper ApplicationHelper
  after_action :set_sent_at

  def papers(subscription, papers)
    @subscription = subscription
    @papers = Paper.where(id: papers)

    subject = 'neue Anfragen'

    if @subscription.subtype == 'body'
      body = Body.find_by_state(@subscription.query)
      subject = I18n.t(:'email.subject.body', count: @papers.size, body: ApplicationController.helpers.body_with_prefix(body))
      @first_line = I18n.t(:'email.new_interpellations.body', count: @papers.size, body: ApplicationController.helpers.body_with_prefix(body))
    elsif @subscription.subtype == 'search'
      subject = I18n.t(:'email.subject.search', count: @papers.size, query: @subscription.query)
      @first_line = I18n.t(:'email.new_interpellations.search', count: @papers.size, query: @subscription.query)
      @show_body = true
    end

    headers['List-Unsubscribe'] = "<#{unsubscribe_url}>"
    mail subject: subject, to: @subscription.email
  end

  private

  def unsubscribe_url
    Rails.application.routes.url_helpers.unsubscribe_url(@subscription, Rails.configuration.action_mailer.default_url_options)
  end

  def set_sent_at
    @subscription.last_sent_at = DateTime.now
    @subscription.save
  end
end

class SubscriptionMailer < ApplicationMailer
  helper ApplicationHelper

  def papers(subscription, papers)
    @subscription = subscription
    @papers = papers

    subject = 'neue kleine Anfragen'

    if @subscription.subtype == 'body'
      body = Body.find_by_state(@subscription.query)
      subject = "#{@papers.size} neue kleine Anfrage#{@papers.size == 1 ? '' : 'n'} aus #{body.name}"
    end

    headers['List-Unsubscribe'] = Rails.application.routes.url_helpers.unsubscribe_url(@subscription, Rails.configuration.action_mailer.default_url_options)
    mail subject: subject, to: @subscription.email
  end
end

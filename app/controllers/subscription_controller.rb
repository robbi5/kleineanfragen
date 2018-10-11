class SubscriptionController < ApplicationController
  before_action :find_subscription, only: [:unsubscribe]

  def subscribe
    @subscription = Subscription.new(subscription_params)

    if @subscription.invalid?
      render :error_invalid, status: :bad_request
      return
    end

    if EmailBlacklist.active_and_email(@subscription.email).exists?
      render :error_blacklist, status: :unauthorized
      return
    end

    @needs_opt_in = OptIn.unconfirmed_and_email(@subscription.email).empty?
    @subscription.active = !@needs_opt_in
    @subscription.save!

    send_opt_in(@subscription) if @needs_opt_in
  end

  def unsubscribe
    @subscription.active = false
    @subscription.save!
  end

  private

  def send_opt_in(subscription)
    @opt_in = OptIn.create!(email: subscription.email)
    OptInMailer.opt_in(@opt_in, subscription).deliver_later
  end

  def subscription_params
    params.require(:subscription).permit(:email, :subtype, :query)
  end

  def find_subscription
    @subscription = Subscription.find_by_hash!(params[:subscription])
  rescue
    render :error_not_found, status: 404
  end
end

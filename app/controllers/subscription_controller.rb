class SubscriptionController < ApplicationController
  before_action :find_subscription, only: [:unsubscribe]

  def subscribe
    @subscription = Subscription.new(subscription_params)
    # FIXME: do we want ip only at opt_in?
    ## @subscription.created_ip = request.remote_ip

    # FIXME: validate here
    if @subscription.invalid?
      case @subscription.subtype
      when :body
        # FIXME: redirect back to body
      when :search
        # FIXME: redirect back to search
      else
        # FIXME: render error message
      end
    end

    @opt_in = OptIn.unconfirmed_and_email(@subscription.email)
    @subscription.active = !@opt_in.empty?
    @subscription.save!

    if @opt_in.empty?
      send_opt_in(@subscription)
    end

    # FIXME: thanks page
  end

  def unsubscribe
    @subscription.active = false
    @subscription.save!

    # FIXME: thanks page
  end

  private

  def send_opt_in(subscription)
    @opt_in = OptIn.create!(email: subscription.email, created_ip: request.remote_ip)
    # FIXME: send opt_in
  end

  def subscription_params
    params.require(:subscription).permit(:email, :subtype, :query)
  end

  def find_subscription
    @subscription = Subscription.find_by_hash(params[:subscription])
  end
end

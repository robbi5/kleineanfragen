class OptInController < ApplicationController
  before_action :find_opt_in
  before_action :find_subscription, only: [:confirm]

  def confirm
    if EmailBlacklist.active_and_email(@subscription.email).exists?
      # FIXME: render error message
      render status: :unauthorized
      return
    end

    if @opt_in.confirmed?
      # FIXME: thanks, but already confirmed
      return
    end

    @opt_in.confirmed_at = DateTime.now
    @opt_in.confirmed_ip = request.remote_ip
    @opt_in.save!

    @subscription.active = true
    @subscription.save!
    # FIXME: thanks page
  end

  def report
    EmailBlacklist.find_or_create_by(email: @opt_in.email.downcase) do |blacklisted|
      blacklisted.reason = :report
    end

    # cannot use update_all here, because it doesn't change updated_at
    Subscription.where(email: @opt_in.email, active: true).each do |sub|
      sub.active = false
      sub.save!
    end

    report = Report.new(Time.now, request.remote_ip, request.user_agent)
    OptInMailer.report(@opt_in, report).deliver_later

    # FIXME: thanks page
  end

  private

  def find_opt_in
    @opt_in = OptIn.find_by_confirmation_token(params[:confirmation_token])
    render :'error/confirmation_token' if @opt_in.nil? # FIXME: page
  end

  def find_subscription
    @subscription = Subscription.find_by_hash(params[:subscription])
    render :'error/subscription' if @subscription.nil? # FIXME: page
  end
end

class OptInController < ApplicationController
  before_action :set_opt_in

  def confirm
    # FIXME: check blacklist
    # FIXME: fill @opt_in
    # FIXME: set @subscription active
    # FIXME: thanks page
  end

  def report
    # FIXME: add user to email blacklist
    # FIXME: set every subscription from email to active=0
    # FIXME: notify admin
    # FIXME: thanks page
  end

  private

  def set_opt_in
    @opt_in = OptIn.find_by_confirmation_token(params[:confirmation_token])
    render :'error/confirmation_token' if @opt_in.nil? # FIXME: page 'email konnte nicht gefunden werden'
    # FIXME: howto break?
  end

  # FIXME: get @subscription for confirm
end

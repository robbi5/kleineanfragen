class Scraper
  def mechanize
    mech = Mechanize.new
    mech.pre_connect_hooks << lambda do |_agent, request|
      Rails.logger.debug "[scraper] mechanize throttle (uri=#{request.path})"
      sleep 2
    end
    mech.user_agent = Rails.configuration.x.user_agent
    mech
  end
end
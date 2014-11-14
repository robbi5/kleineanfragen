class Scraper
  def mechanize
    mech = Mechanize.new
    mech.pre_connect_hooks << lambda { |agent, request|
      Rails.logger.debug "[scraper] mechanize throttle (uri=#{request.path})"
      sleep 2
    }
    # mech.user_agent = "#{self.class.name} kleineanfragen"
    mech
  end
end
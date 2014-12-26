require 'mechanize'

class Scraper
  def initialize(legislative_term)
    @legislative_term = legislative_term
    @per_page = 50
  end

  def supports_pagination?
    false
  end

  def mechanize
    mech = Mechanize.new
    mech.pre_connect_hooks << lambda do |_agent, request|
      Rails.logger.debug "[scraper] mechanize throttle (uri=#{request.path})"
      sleep 2
    end
    mech.user_agent = Rails.configuration.x.user_agent
    mech
  end

  def warn_broken(bool, reason, item = nil)
    return false if !bool
    Rails.logger.warn reason
    Rails.logger.debug { item.to_s.gsub(/\n|\s\s+/, '') } unless item.nil?
    true
  end
end
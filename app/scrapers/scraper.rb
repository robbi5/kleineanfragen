require 'mechanize'

class Scraper
  def initialize(legislative_term)
    @legislative_term = legislative_term
    @per_page = 50
  end

  def logger=(logger)
    @logger = logger
  end

  def logger
    @logger ||= Rails.logger
  end

  def supports_pagination?
    false
  end

  def supports_streaming?
    false
  end

  def mechanize
    mech = Mechanize.new
    mech.read_timeout = 60
    mech.pre_connect_hooks << lambda do |_agent, request|
      logger.debug "[scraper] mechanize throttle (uri=#{request.path})"
      sleep 1
    end
    mech.user_agent = Rails.configuration.x.user_agent
    mech
  end

  def warn_broken(bool, reason, item = nil)
    return false if !bool
    logger.warn reason
    logger.debug { item.to_s.gsub(/\n|\s\s+/, '') } unless item.nil?
    true
  end

  def self.patron_session
    sess = Patron::Session.new
    sess.connect_timeout = 8
    sess.timeout = 60
    sess.headers['User-Agent'] = Rails.configuration.x.user_agent
    sess
  end
end
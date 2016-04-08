require 'typhoeus'
require 'typhoeus/adapters/faraday'
# Ethon.logger = Logger.new('/dev/null')

Typhoeus::Config.user_agent = Rails.configuration.x.user_agent

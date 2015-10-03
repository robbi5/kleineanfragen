require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Kleineanfragen
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.autoload_paths += %W(#{Rails.root}/lib)
    config.autoload_paths += %W(#{Rails.root}/app/jobs)
    config.autoload_paths += %W(#{Rails.root}/app/scrapers)
    config.autoload_paths += %W(#{Rails.root}/app/extractors)
    config.autoload_paths += %W(#{Rails.root}/app/validators)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.available_locales = :de
    config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Disable image optim for assets
    config.assets.image_optim = false

    # active job
    config.active_job.queue_adapter = :resque

    # applicaton config:
    # path for storing paper pdfs
    config.x.paper_storage = Rails.root.join('data')
    # User-Agent for scraping and download
    config.x.user_agent = 'kleineanfragen-scraper (scraper@kleineanfragen.de)'
    # Tika Server URL for extracting text from papers
    config.x.tika_server = ENV['TIKA_SERVER_URL'] || false
    # Nomenklatura API Key
    config.x.nomenklatura_api_key = ENV['NOMENKLATURA_APIKEY'] || false
    # used email addresses
    config.x.email_from = 'kleineAnfragen <noreply@kleineanfragen.de>'
    config.x.email_support = 'kleineAnfragen support <hallo@kleineanfragen.de>'
    # set from address
    config.action_mailer.default_options = { from: config.x.email_from }
    # report slack webhook url
    config.x.report_slack_webhook = ENV['REPORT_SLACK_WEBHOOK']
  end
end

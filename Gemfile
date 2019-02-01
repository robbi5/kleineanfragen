source 'https://rubygems.org'

ruby '2.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.0.1'
# Use postgresql as the database for Active Record
gem 'pg', '0.20.0'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.2.1'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5.0'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3'

# logging
gem 'lograge', '~> 0.9.0'
gem 'grape_logging', '~> 1.6'

gem 'foreman', '~> 0.78.0', group: :development
gem 'dotenv-rails', '~> 1.0.2'
gem 'sentry-raven', '~> 2.7.2'

# Access an IRB console on exception pages or by using <%%= console %> in views
gem 'web-console', '~> 3.0', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  ## removed, because its not useful in a docker container
  # gem 'spring'
  gem 'rubocop'
end

group :test do
  gem 'sqlite3'
  gem 'memory_test_fix', '~> 1.4.0'
  gem 'minitest', '5.10.1'
  gem 'minitest-stub_any_instance'
  gem 'rails-controller-testing', '~> 1.0.1'
  gem 'webmock'
end

# Get i18n files
gem 'rails-i18n', '~> 5.0.0'

# scraping
gem 'mechanize', '~> 2.7.3'
gem 'rubyzip', '~> 1.2.2'
gem 'saxerator', '~> 0.9.5'

# slugs
gem 'friendly_id', '~> 5.2.0'

# don't delete everything
gem 'paranoia', '~> 2.4.0'

# fix urls while scraping
gem 'addressable', '~> 2.4.0', require: 'addressable/uri'

# styling
gem 'bootstrap-sass', '~> 3.3.6'
gem 'inline_svg', '~> 1.3.1'

# pagination
gem 'kaminari', '~> 0.17.0'

# pdf text extraction
gem 'docsplit', '~> 0.7.6'
gem 'abbyy', '~> 0.2.1'

# pdf thumbnailing
gem 'image_optim', '~> 0.26.1'
gem 'image_optim_pack', '~> 0.5.0.20180124'

# search!
gem 'searchkick', '3.1.1'
gem 'patron', '~> 0.7.1'
gem 'typhoeus', '~> 1.3.0'

# storage
# gem 'fog', '~> 1.29.0'
#  - fog loads way too many provider gems. load only the ones we need:
gem 'fog-aws', '~> 1.3.0'
gem 'fog-local', '~> 0.2.1'

# jobs
gem 'redis', '>= 3.3.5', '< 5'
gem 'sidekiq', '~> 5.2.1'

# for nomenklatura
gem 'httparty', '~> 0.16.0'

# matching against known names in scrapers
gem 'fuzzy_match', '~> 2.1.0'

# simple title and opengraph/twitter cards view helpers
gem 'tophat', '~> 2.3.0'

# email urls
gem 'hashids', '~> 1.0.2'

# inline css for emails
gem 'nokogiri'
gem 'premailer-rails', '~> 1.9.1'

# simplify posting to slack channels
gem 'slack-notifier', '~> 2.3.2'

# incoming email
gem 'griddler', '~> 1.4.0'
gem 'griddler-sendgrid', '~> 1.0.1'

# api
gem 'rack-cors', '~> 1.0.2', require: 'rack/cors'
gem 'grape', '~> 0.17.0'
gem 'grape-entity', '~> 0.6.1'
gem 'grape-route-helpers', '~> 2.0.0'

# wikidata
gem 'wikidata-client', '~> 0.0.10'
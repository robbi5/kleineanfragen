source 'https://rubygems.org'

ruby '2.3.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use postgresql as the database for Active Record
gem 'pg'
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Turbolinks <3 jquery
gem 'jquery-turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.3'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use newrelic
gem 'newrelic_rpm', group: :production

gem 'foreman', '~> 0.78.0', group: :development
gem 'dotenv-rails', '~> 1.0.2'
gem 'sentry-raven'

# Access an IRB console on exception pages or by using <%%= console %> in views
gem 'web-console', '~> 3.0', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  ## removed, because its not useful in a docker container
  # gem 'spring'
end

gem 'sqlite3', group: :test
gem 'memory_test_fix', group: :test
gem 'minitest-stub_any_instance', group: :test

# Get i18n files
gem 'rails-i18n', '~> 4.0.0'

# scraping
gem 'mechanize', '~> 2.7.3'
gem 'rubyzip', '~> 1.2.0'
gem 'saxerator', '~> 0.9.5'

# slugs
gem 'friendly_id', '~> 5.1.0'

# fix urls while scraping
gem 'addressable', '~> 2.4.0', require: 'addressable/uri'

# styling
gem 'bootstrap-sass', '~> 3.3.4'

# pagination
gem 'kaminari', '~> 0.16.0'

# pdf text extraction
gem 'docsplit', '~> 0.7.6'
gem 'abbyy', '~> 0.2.1'

# pdf thumbnailing
gem 'image_optim', '~> 0.22.0'

# search!
gem 'searchkick', '~> 0.9.1'
gem 'patron', '~> 0.5.1'
gem 'typhoeus', '~> 1.0.1'

# storage
# gem 'fog', '~> 1.29.0'
#  - fog loads way too many provider gems. load only the ones we need:
gem 'fog-aws', '~> 0.7.6'
gem 'fog-local', '~> 0.2.1'

# jobs
gem 'resque', '~> 1.26.0'
gem 'resque-scheduler', '~> 4.1.0'
gem 'activejob-retry', '~> 0.5.0'
gem 'resque-sentry', '~> 1.2.0'

# for nomenklatura
gem 'httparty', '~> 0.13.7'

# matching against known names in scrapers
gem 'fuzzy_match', '~> 2.1.0'

# simple title and opengraph/twitter cards view helpers
gem 'tophat', '~>2.2.0'

# email urls
gem 'hashids', '~> 1.0.2'

# inline css for emails
gem 'nokogiri'
gem 'premailer-rails', '~> 1.9.1'

# simplify posting to slack channels
gem 'slack-notifier', '~> 1.5.1'
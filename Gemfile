source 'https://rubygems.org'

ruby '2.1.5'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
# Use postgresql as the database for Active Record
gem 'pg'
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
gem 'jbuilder', '~> 2.2'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0',          group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
gem 'unicorn', '~> 4.8.3', group: :production

# Use newrelic
gem 'newrelic_rpm', group: :production

gem 'foreman', '~> 0.76.0', group: :development
gem 'dotenv-rails', '~> 1.0.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Access an IRB console on exception pages or by using <%%= console %> in views
  gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

# Get i18n files
gem 'rails-i18n', '~> 4.0.0'

# scraping
gem 'mechanize',  '~> 2.7.3'

# slugs
gem 'friendly_id', '~> 5.0.0'

# fix urls while scraping
gem 'addressable', '~> 2.3.6', require: 'addressable/uri'

# styling
gem 'bootstrap-sass', '~> 3.3.1.0'
gem 'autoprefixer-rails', '~> 4.0.1'

# pagination
gem 'kaminari', '~> 0.16.0'

# pdf text extraction
gem 'docsplit', '~> 0.7.6'

# search!
gem 'searchkick', '~> 0.8.5'
gem 'patron', '~> 0.4.18'

# storage
# pinned to 1.24.0 until radosgw speaks AWS Signature v4
# or a fallback is available: https://github.com/fog/fog/issues/3299
gem 'fog', '1.24.0'

# jobs
gem 'resque', '~> 1.25.2'

# for nomenklatura
gem 'httparty', '~> 0.13.3'

# simple title and opengraph/twitter cards view helpers
gem 'tophat', '~>2.2.0'
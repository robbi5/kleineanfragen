FROM ruby:2.2.2

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client nodejs poppler-utils advancecomp gifsicle jhead jpegoptim libjpeg-progs optipng pngcrush pngquant

RUN mkdir /app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install

ADD . /app

EXPOSE 5000
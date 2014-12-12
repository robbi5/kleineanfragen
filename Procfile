web: bundle exec rails server -p $PORT
worker: TERM_CHILD=1 QUEUE=* bundle exec rake environment resque:work
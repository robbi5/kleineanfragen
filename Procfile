web: bundle exec rails server -b 0.0.0.0 -p $PORT
worker: TERM_CHILD=1 QUEUE=* bundle exec rake environment resque:work
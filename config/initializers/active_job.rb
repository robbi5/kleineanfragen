ActiveJob::Base.queue_adapter = :resque
ActiveJob::Base.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new('log/active_job.log'))
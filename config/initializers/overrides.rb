# ActiveJob-Retry is calling `ActiveJob::Base.queue_adapter.name`
# https://github.com/isaacseymour/activejob-retry/blob/33b9b5dc4c04cd8127e67c8682228b710c93189e/lib/active_job/retry.rb#L105
#
# this doesn't work, but we're also not using one of those "PROBLEMATIC_ADAPTERS"
# so simply remove it.
#
module ActiveJob
  class Retry < Module
     def check_adapter!
      # do nothing.
    end
  end
end
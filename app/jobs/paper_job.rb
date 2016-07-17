class PaperJob < ApplicationJob
  # override define_callbacks from active_job/callbacks.rb to support termination
  define_callbacks :perform, terminator: ->(_target, result) { result == false }

  # before_perform with a symbol doesn't get job as argument, so wrap it here
  before_perform ->(job) { skip_if_frozen(job) }

  def skip_if_frozen(job)
    paper = job.arguments.first
    if paper.frozen?
      logger.info "Skipping because Paper [#{paper.body.state} #{paper.full_reference}] is frozen"
      false
    end
  end
end
class PaperJob < ApplicationJob
  # before_perform with a symbol doesn't get job as argument, so wrap it here
  before_perform ->(job) { skip_if_frozen(job) }

  def skip_if_frozen(job)
    paper = job.arguments.first
    if paper.frozen?
      logger.info "Skipping because Paper [#{paper.body.state} #{paper.full_reference}] is frozen"
      throw :abort
    end
  end
end
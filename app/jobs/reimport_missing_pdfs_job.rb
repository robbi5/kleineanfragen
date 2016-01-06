class ReimportMissingPDFsJob < ActiveJob::Base
  queue_as :meta

  def perform
    Paper.where(downloaded_at: nil).where.not(url: nil).find_each do |paper|
      logger.info "Adding reimport of Paper [#{paper.body.state} #{paper.full_reference}] to queue"
      StorePaperPDFJob.perform_later(paper, force: true)
    end
  end
end
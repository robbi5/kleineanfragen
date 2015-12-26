class ReimportHessenPapersPDFJob < ActiveJob::Base
  queue_as :meta

  DISTANCE = 14.days

  def perform
    body = Body.find_by_state('HE')
    papers = Paper.where(body: body).where(['pdf_last_modified < ?', Date.today - DISTANCE]).where(contents: nil)

    papers.find_each do |paper|
      logger.info "Adding reimport of Paper [#{paper.body.state} #{paper.full_reference}] to queue"
      StorePaperPDFJob.perform_later(paper, force: true)
    end
  end
end
class ReimportPapersPDFJob < ActiveJob::Base
  queue_as :meta

  DISTANCE = 5.days

  def perform
    bt = Body.find_by_state('BT')
    papers = Paper.where(body: bt).where(['pdf_last_modified < ?', Date.today - DISTANCE]).where("contents LIKE '%Korrektur\nDrucksache%'")

    papers.each do |paper|
      logger.info "Adding reimport of Paper [#{paper.body.state} #{paper.full_reference}] to queue"
      StorePaperPDFJob.perform_later(paper, force: true)
    end
  end
end
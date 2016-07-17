class ReimportPapersPDFJob < ApplicationJob
  queue_as :meta

  DISTANCE = 5.days
  STATES = {
    'BT' => '%Korrektur\nDrucksache%',
    'HB' => '%Vorläufige, unredigierte Fassung%'
  }

  def perform
    STATES.each do |state, like_query|
      body = Body.find_by_state(state)
      papers = Paper.where(body: body).where(['pdf_last_modified < ?', Date.today - DISTANCE]).where('contents LIKE ?', like_query)

      papers.find_each do |paper|
        logger.info "Adding reimport of Paper [#{paper.body.state} #{paper.full_reference}] to queue"
        StorePaperPDFJob.perform_later(paper, force: true)
      end
    end
  end
end
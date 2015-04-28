class ExtractAnswerersJob < PaperJob
  queue_as :meta

  def perform(paper)
    # FIXME: generic?
    return unless paper.body.state == 'BY'
    logger.info "Extracting Answerers from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    answerers = BayernPDFExtractor.new(paper).extract_answerers
    if answerers.nil?
      logger.warn "No Answerers found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    logger.warn "No Ministries found in Paper [#{paper.body.state} #{paper.full_reference}]" if answerers[:ministries].blank?

    paper.answerers = answerers
    paper.save
  end
end
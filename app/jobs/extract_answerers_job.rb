class ExtractAnswerersJob < PaperJob
  queue_as :meta

  EXTRACTORS = {
    'BB' => BrandenburgPDFExtractor,
    'BE' => BerlinPDFExtractor,
    'BY' => BayernPDFExtractor,
    'HE' => HessenPDFExtractor
  }

  def perform(paper)
    return unless EXTRACTORS.keys.include?(paper.body.state)
    logger.info "Extracting Answerers from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    answerers = EXTRACTORS[paper.body.state].new(paper).extract_answerers
    if answerers.nil?
      logger.warn "No Answerers found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    logger.warn "No Ministries found in Paper [#{paper.body.state} #{paper.full_reference}]" if answerers[:ministries].blank?

    paper.answerers = answerers
    paper.save
  end
end
class ExtractPublishedAtJob < PaperJob
  queue_as :meta

  EXTRACTORS = {
    'HB' => BremenPDFExtractor
  }

  def perform(paper)
    return unless EXTRACTORS.keys.include?(paper.body.state)
    logger.info "Extracting published_at from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    published_at = EXTRACTORS[paper.body.state].new(paper).extract_published_at
    if published_at.nil?
      logger.warn "No published_at found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    paper.published_at = published_at
    paper.save
  end
end
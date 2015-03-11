class ExtractOriginatorsJob < ActiveJob::Base
  queue_as :meta

  EXTRACTORS = {
    'BY' => BayernPDFExtractor,
    'BT' => BundestagPDFExtractor,
    'SL' => SaarlandPDFExtractor
  }

  def perform(paper)
    return unless EXTRACTORS.keys.include?(paper.body.state)
    logger.info "Extracting Originators from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    originators = EXTRACTORS[paper.body.state].new(paper).extract_originators
    if originators.nil?
      logger.warn "No Names found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    logger.warn "No Parties found in Paper [#{paper.body.state} #{paper.full_reference}]" if originators[:parties].blank?
    logger.warn "No People found in Paper [#{paper.body.state} #{paper.full_reference}]" if originators[:people].blank?

    paper.originators = originators
    paper.save
  end
end
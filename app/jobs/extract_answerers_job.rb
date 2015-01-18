class ExtractAnswerersJob < ActiveJob::Base
  queue_as :meta

  def perform(paper)
    # FIXME: generic?
    return unless paper.body.state == 'BY'
    Rails.logger.info "Extracting Answerers from Paper [#{paper.body.state} #{paper.full_reference}]"

    fail "No Text for Paper [#{paper.body.state} #{paper.full_reference}]" if paper.contents.blank?

    answerers = BayernPDFExtractor.new(paper).extract_answerers
    if answerers.nil?
      Rails.logger.warn "No Answerers found in Paper [#{paper.body.state} #{paper.full_reference}]"
      return
    end

    Rails.logger.warn "No Ministries found in Paper [#{paper.body.state} #{paper.full_reference}]" if answerers[:ministries].blank?

    paper.answerers = answerers
    paper.save
  end
end
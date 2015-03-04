class ImportPaperJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term, reference)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    scraper = body.scraper::Detail.new(legislative_term, reference)
    scraper.logger = logger
    load_details = body.scraper.const_defined?(:Detail)
    logger.info "Importing single Paper: #{body.state} - #{legislative_term}/#{reference}"
    item = scraper.scrape
    if Paper.unscoped.where(body: body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      logger.info "Paper already exists, updating: [#{item[:reference]}] \"#{item[:title]}\""
      paper = Paper.unscoped.where(body: body, legislative_term: item[:legislative_term], reference: item[:reference]).first
      paper.assign_attributes(item.except(:full_reference, :body, :legislative_term, :reference))
      paper.save!
    else
      logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
      paper = Paper.create!(item.except(:full_reference).merge(body: body))
    end
    LoadPaperDetailsJob.perform_later(paper) if paper.originators.blank? && load_details
    StorePaperPDFJob.perform_later(paper)
  end
end

# Paper existiert nicht: create
# Existiert, is_answer: true: update
# Existiert, is_answer: true: update

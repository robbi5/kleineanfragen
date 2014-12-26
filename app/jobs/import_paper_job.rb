class ImportPaperJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term, reference)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    scraper = body.scraper::Detail.new(legislative_term, reference)
    load_details = body.scraper.const_defined?(:Detail)
    Rails.logger.info "Importing single Paper: #{body.state} - #{legislative_term} / #{page}"
    item = scraper.scrape
    if Paper.where(body: body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      Rails.logger.info "Paper already exists: [#{item[:reference]}] \"#{item[:title]}\""
      return
    end
    Rails.logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
    paper = Paper.create!(item.except(:full_reference).merge({ body: body }))
    LoadPaperDetailsJob.perform_later(paper) if paper.originators.blank? && load_details
    StorePaperPDFJob.perform_later(paper)
  end
end
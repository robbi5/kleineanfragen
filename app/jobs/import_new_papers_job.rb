class ImportNewPapersJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    scraper = body.scraper::Overview.new(legislative_term)
    page = 1
    found_new_paper = false
    loop do
      Rails.logger.info "Importing #{body.state} - Page #{page}"
      found_new_paper = false
      scraper.scrape(page).each do |item|
        next if Paper.where(body: body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
        Rails.logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
        paper = Paper.create!(item.except(:full_reference).merge({ body: body }))
        found_new_paper = true
        LoadPaperDetailsJob.perform_later(paper) if paper.originators.blank?
        StorePaperPDFJob.perform_later(paper)
      end
      page += 1
      break unless found_new_paper
    end
    Rails.logger.info "Importing #{body.state} done. Scraped #{page} Pages"
  end
end
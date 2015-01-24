class ImportNewPapersJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    @body = body
    @legislative_term = legislative_term
    @scraper = @body.scraper::Overview.new(legislative_term)
    @load_details = @body.scraper.const_defined?(:Detail)
    if @scraper.supports_pagination?
      scrape_paginated
    else
      scrape_single_page
    end
    logger.info "Importing #{@body.state} done."
  end

  def scrape_paginated
    page = 1
    found_new_paper = false
    loop do
      logger.info "Importing #{@body.state} - Page #{page}"
      found_new_paper = false
      @scraper.scrape(page).each do |item|
        next if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
        on_item(item)
        found_new_paper = true
      end
      page += 1
      break unless found_new_paper
    end
  end

  def scrape_single_page
    logger.info "Importing #{@body.state} - Single Page"
    block = lambda do |item|
      return if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      on_item(item)
    end
    if @scraper.supports_streaming?
      @scraper.scrape(&block)
    else
      @scraper.scrape.each block
    end
  end

  def on_item(item)
    logger.info "New Paper: [#{item[:reference]}] \"#{item[:title]}\""
    paper = Paper.create!(item.except(:full_reference).merge(body: @body))
    LoadPaperDetailsJob.perform_later(paper) if (item[:originators].blank? || item[:answerers].blank?) && @load_details
    StorePaperPDFJob.perform_later(paper)
  end
end
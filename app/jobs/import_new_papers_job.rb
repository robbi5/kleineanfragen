class ImportNewPapersJob < ActiveJob::Base
  queue_as :import

  def perform(body, legislative_term)
    fail "No scraper found for body #{body.state}" if body.scraper.nil?
    @body = body
    @legislative_term = legislative_term
    @scraper = @body.scraper::Overview.new(legislative_term)
    @scraper.logger = logger
    @load_details = @body.scraper.const_defined?(:Detail)
    @new_papers = 0
    @old_papers = 0
    if @scraper.supports_pagination?
      scrape_paginated
    else
      scrape_single_page
    end
    logger.info "Importing #{@body.state} #{@legislative_term} done. #{@new_papers} new Papers, #{@old_papers} old Papers."
  end

  def scrape_paginated
    page = 1
    found_new_paper = false
    loop do
      logger.info "Importing #{@body.state} - Page #{page}"
      found_new_paper = false
      @scraper.scrape_paginated(page) do |item|
        puts "P #{item[:reference]}"
        if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference], is_answer: true).exists?
          @old_papers += 1
          next
        end
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
      if Paper.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference], is_answer: true).exists?
        @old_papers += 1
        return
      end
      on_item(item)
    end
    if @scraper.supports_streaming?
      @scraper.scrape(&block)
    else
      @scraper.scrape.each(&block)
    end
  end

  def on_item(item)
    if Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).exists?
      logger.info "[#{@body.state}] Updating Paper: [#{item[:full_reference]}] \"#{item[:title]}\""
      paper = Paper.unscoped.where(body: @body, legislative_term: item[:legislative_term], reference: item[:reference]).first
      paper.assign_attributes(item.except(:full_reference, :body, :legislative_term, :reference))
      paper.save!
    else
      logger.info "[#{@body.state}] New Paper: [#{item[:full_reference]}] \"#{item[:title]}\""
      paper = Paper.create!(item.except(:full_reference).merge(body: @body))
    end
    LoadPaperDetailsJob.perform_later(paper) if (item[:originators].blank? || item[:answerers].blank?) && @load_details
    StorePaperPDFJob.perform_later(paper)
    @new_papers += 1
  end
end